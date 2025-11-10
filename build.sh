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

escape_for_html() {
    # Escape some characters for HTML

    escaped=$1

    escaped=${escaped//&/\&amp;}
    escaped=${escaped//</\&lt;}
    escaped=${escaped//>/\&gt;}

    echo "$escaped"
}

escape_for_sed() {
    # Escape some characters for sed

    escaped=$1

    escaped=${escaped//\\/\\\\}
    escaped=${escaped//\//\\/}
    escaped=${escaped//\&/\\\&}

    echo "$escaped"
}

strip_styles() {
    # Strip the styles

    sed -zi "s/<style[^>]*>[^<]*<\/style>//" $1
    sed -i "s/style=\"[^\"]*\"//" $1
}

keep_body_only() {
    # Remove everything except <body>'s contents.

    sed -zi -e "s/.*<body[^>]*>//" -e "s/<\/body>.*//" $1
}

avoid_tag_replacement() {
    # FIXME: Do not replace them in <style> tags.

    #sed -i -e "s/{/\&#123;/g" -e "s/}/\&#125;/g" $1

    echo "FIXME: Fix curly brace escaping code."
}

projects=$(cat $projects)

echo "" > $bdir/projects.html

for i in ${projects[@]}; do
    name=${i%;*}
    path=${i#*;}

    mkdir -p $(dirname $bdir/$path.html)

    preconv $path | groff -mwww -ms -Thtml > $bdir/$path.html

    escaped=$(escape_for_html $name)

    html=$escaped

    escaped=$(escape_for_sed $escaped)

    # Postprocess the HTML

    strip_styles $bdir/$path.html

    keep_body_only $bdir/$path.html

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
    ext=${f#*.}

    # Check if the ID has already been used.

    if [[ "$IFS${known_ids[*]}$IFS" =~ "$IFS$id$IFS" ]]; then
        echo "ID \`$id' already used!"
        exit 1
    fi

    mkdir -p $(dirname $o)

    keep_styles=false

    # Generate the HTML code.

    case "$ext" in
        lyx) lyx --export-to xhtml $o $f
             keep_styles=true ;;
        ms) preconv $f | eqn | tbl | refer | pic | \
            groff -mwww -ms -Thtml > $o ;;
        html) cp $f $o ;;
        *) echo "Unsupported file type. Skipping..."
    esac

    # Generate the PDFs.

    case "$ext" in
        lyx) lyx --export-to pdf $p $f
             keep_styles=true ;;
        ms) preconv $f | eqn | tbl | refer | pic | \
            groff -mwww -ms -Tps | ps2pdf -dPDFSETTINGS=/prepress \
                                          -dEmbedAllFonts=true - $p ;;
        *) echo "PDF export not supported for this file type..."
    esac

    # Strip some HTML code

    title=$(sed -z -e "s/.*<h1[^>]*>//g" -e "s/<\/h1>.*//g" $o)

    # Add the article to the article list

    article_list+="<a href=\"$adir/$id.html\">$title</a></br>"

    # Strip all the unneeded stuff

    if [ $keep_styles = true ]; then
        sed -zi -e "s/.*<style[^>]*>/<style>/" \
                -e "s/<\/style>.*<body[^>]*>/<\/style>/" \
                -e "s/<\/body>.*//" $o
    else
        keep_body_only $o
    fi

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
preconv welcome.ms | groff -mwww -ms -Thtml > $bdir/welcome.html

sed -zi -e "s/.*<body[^>]*>//" -e "s/<\/body>.*//" -e "s/align=\"center\"//g" \
        -e "s/style=\"[^\"]*\"//" $bdir/welcome.html

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
