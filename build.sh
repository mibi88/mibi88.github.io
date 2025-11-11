#!/bin/bash

projects=projects.txt
# Directory containing all the build data
bdir=build
# Directory containing all the article pages
adir=all
# Directory containing all the articles as PDFs.
pdir=pdf

recent_articles_max=5

mkdir -p $bdir

# Generate the project list

IFS="
"

# USAGE: escape_for_html STRING
#
# Outputs the string with escape sequences on stdout.
escape_for_html() {
    # Escape some characters for HTML

    escaped=$1

    escaped=${escaped//&/\&amp;}
    escaped=${escaped//</\&lt;}
    escaped=${escaped//>/\&gt;}

    echo "$escaped"
}

# USAGE: escape_for_sed STRING
#
# Outputs the string with escape sequences on stdout.
escape_for_sed() {
    # Escape some characters for sed

    escaped=$1

    escaped=${escaped//\\/\\\\}
    escaped=${escaped//\//\\/}
    escaped=${escaped//\&/\\\&}

    echo "$escaped"
}

# USAGE: strip_styles FILE
#
# Remove all the styles from a html page.
strip_styles() {
    # Strip the styles

    sed -zi "s/<style[^>]*>[^<]*<\/style>//" $1
    sed -i "s/style=\"[^\"]*\"//" $1
}

# USAGE: remove_html_structure FILE KEEP_STYLES
#
# Only keep the body and the styles if KEEP_STYLES is set to `true'
remove_html_structure() {
    if [ $2 = true ]; then
        # Remove everything except <body>'s contents and the styles.

        sed -zi -e "s/.*<style[^>]*>/<style>/" \
                -e "s/<\/style>.*<body[^>]*>/<\/style>/" \
                -e "s/<\/body>.*//" $1
    else
        # Remove everything except <body>'s contents.

        sed -zi -e "s/.*<body[^>]*>//" -e "s/<\/body>.*//" $1
    fi
}

# USAGE: avoid_tag_replacement FILE
#
# Escape curly braces to avoid them getting replaced when generating HTML from
# a template.
avoid_tag_replacement() {
    # FIXME: Do not replace them in <style> tags.

    #sed -i -e "s/{/\&#123;/g" -e "s/}/\&#125;/g" $1

    echo "FIXME: Fix curly brace escaping code."
}

# USAGE: gen_html INPUT OUTPUT
#
# Generate HTML code from a file, such as a roff .ms file.
gen_html() {
    # Generate the HTML code.

    ext=${1#*.}

    case "$ext" in
        lyx) lyx --export-to xhtml $2 $1
             echo "true"
             exit 0 ;;
        ms) preconv $1 | eqn | tbl | refer | pic | \
            groff -mwww -ms -Thtml > $2 ;;
        html) cp $1 $2 ;;
        *) echo "Unsupported file type. Skipping..."
    esac

    echo "false"
}

# USAGE: gen_pdf INPUT OUTPUT
#
# Generate a PDF from a file, such as a roff .ms file.
gen_pdf() {
    # Generate the PDFs.

    ext=${1#*.}

    case "$ext" in
        lyx) lyx --export-to pdf $2 $1 ;;
        ms) preconv $1 | eqn | tbl | refer | pic | \
            groff -mwww -ms -Tps | ps2pdf -dPDFSETTINGS=/prepress \
                                          -dEmbedAllFonts=true - $2 ;;
        html) pandoc $1 --pdf-engine pdfroff -o $2 ;;
        *) echo "PDF export not supported for this file type..."
    esac
}

projects=$(cat $projects)

echo "" > $bdir/projects.html

for i in ${projects[@]}; do
    name=${i%;*}
    path=${i#*;}

    mkdir -p $(dirname $bdir/$path.html)

    keep_styles=$(gen_html $path $bdir/$path.html)

    escaped=$(escape_for_html $name)

    html=$escaped

    escaped=$(escape_for_sed $escaped)

    # Postprocess the HTML

    strip_styles $bdir/$path.html

    remove_html_structure $bdir/$path.html $keep_styles

    # Add the title and put it into the template

    echo "<h1>$html</h1>$(cat $bdir/$path.html)" > $bdir/$path.html

    avoid_tag_replacement $bdir/$path.html

    sed "/{project}/{
            s/{project}//
            r $bdir/$path.html
        }" project_template.html >> $bdir/projects.html
done

# Generate the recent article list and the article pages

mkdir -p $adir

articles=$(cat articles/list.txt)
article_list=""

echo "" > $bdir/recent_articles.html

mkdir -p $pdir

# The list of already used IDs.
known_ids=()

# The article count.
c=0

for i in ${articles[@]}; do
    f=${i#*;}
    id=${i%;*}

    o=$bdir/${f%.*}.html
    p=$pdir/$id.pdf

    # Check if the ID has already been used.

    if [[ "$IFS${known_ids[*]}$IFS" =~ "$IFS$id$IFS" ]]; then
        echo "ID \`$id' already used!"
        exit 1
    fi

    mkdir -p $(dirname $o)

    keep_styles=$(gen_html $f $o)

    gen_pdf $f $p

    # Extract the title from the HTML code

    title=$(sed -z -e "s/.*<h1[^>]*>//g" -e "s/<\/h1>.*//g" $o)

    # Add the article to the article list

    article_list+="<a href=\"$adir/$id.html\">$title</a></br>"

    # Strip all the unneeded stuff

    remove_html_structure $o $keep_styles

    echo "<div class=\"article\">$(cat $o)</div>" > $o

    escaped=$(escape_for_sed $title)

    avoid_tag_replacement $o

    sed -e "s/{title}/$escaped/" \
        -e "/{article}/{
                s/{article}//
                r $o
            }" \
        article_template.html > $adir/$id.html

    # Add the article to the recent articles if we haven't added at most
    # $recent_articles_max articles to it.

    if [ $c -lt $recent_articles_max ]; then
        cat $o >> $bdir/recent_articles.html
    fi

    # Increase the article count

    c=$(($c+1))

    known_ids+=($id)
done

# Generate the welcome text.
keep_styles=$(gen_html welcome.ms $bdir/welcome.html)

remove_html_structure $bdir/welcome.html $keep_styles

strip_styles $bdir/welcome.html

# Remove the align tag

sed -zi "s/<h1 align=\"center\">/<h1>/g" $bdir/welcome.html

# Do not generate index.html if $strip_html_structure is disabled, as it would
# produce invalid html.

IFS=""

article_list=$(escape_for_sed $article_list)

avoid_tag_replacement $bdir/welcome.html
avoid_tag_replacement $bdir/projects.html
avoid_tag_replacement $bdir/recent_articles.html

sed -e "s/{current_year}/$(date +%Y)/g" \
    -e "s/{article_list}/$article_list/" \
    -e "/{welcome}/{
            s/{welcome}//
            r $bdir/welcome.html
        }" \
    -e "/{projects}/{
            s/{projects}//
            r $bdir/projects.html
        }" \
    -e "/{articles}/{
            s/{articles}//
            r $bdir/recent_articles.html
        }" \
    index_template.html > index.html

unset IFS
