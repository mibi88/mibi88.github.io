#!/bin/bash

projects=projects.txt
# Directory containing all the build data
bdir=build
# Directory containing all the article pages
adir=all
# Directory containing all the articles as PDFs.
pdir=pdf

recent_articles_max=5

strip_html_structure=true

mkdir -p $bdir

# Generate the project list

IFS="
"

projects=$(cat $projects)

if [ $strip_html_structure = true ]; then
    echo "" > $bdir/projects.html
fi

for i in ${projects[@]}; do
    name=${i%;*}
    path=${i#*;}

    mkdir -p $(dirname $bdir/$path.html)

    preconv $path | groff -mwww -ms -Thtml > $bdir/$path.html

    escaped=$name

    # Escape some characters for HTML

    escaped=${escaped//&/\&amp;}
    escaped=${escaped//</\&lt;}
    escaped=${escaped//>/\&gt;}

    html=$escaped

    # Escape some characters for sed
    escaped=${escaped//\\/\\\\}
    escaped=${escaped//\//\\/}
    escaped=${escaped//\&/\\\&}

    # Postprocess the HTML
    sed -zi "s/<style[^>]*>[^<]*<\/style>//" $bdir/$path.html
    sed -i "s/style=\"[^\"]*\"//" $bdir/$path.html
    sed -zi "s/<title[^>]*>[^<]*<\/title>/<title>$escaped<\/title>\
<h1>$escaped<\/h1>/" $bdir/$path.html

    if [ $strip_html_structure = true ]; then
        sed -zi "s/.*<body>//" $bdir/$path.html
        sed -zi "s/<\/body>.*//" $bdir/$path.html

        echo "<h1>$html</h1>$(cat $bdir/$path.html)" > $bdir/$path.html

        sed "/{project}/{
s/{project}//
r $bdir/$path.html
}" project_template.html >> $bdir/projects.html
    fi
done

# Generate the recent article list and the article pages

mkdir -p $adir

articles=$(cat articles/list.txt)
article_list=""

echo "" > $bdir/recent_articles.html

known_ids=()

mkdir -p $pdir

c=0
for i in ${articles[@]}; do
    f=${i#*;}
    id=${i%;*}

    o=$bdir/${f%.*}.html
    p=$pdir/$id.pdf
    ext=${f#*.}
    mkdir -p $(dirname $o)
    echo $o $ext
    keep_styles=false
    case "$ext" in
        lyx) lyx --export-to xhtml $o $f
             keep_styles=true ;;
        ms) preconv $f | eqn | tbl | refer | pic | \
            groff -mwww -ms -Thtml > $o ;;
        html) cp $f $o ;;
        *) echo "Unsupported file type. Skipping..."
    esac

    case "$ext" in
        lyx) lyx --export-to pdf $p $f
             keep_styles=true ;;
        ms) preconv $f | eqn | tbl | refer | pic | \
            groff -mwww -ms -Tps | ps2pdf -dPDFSETTINGS=/prepress \
                                          -dEmbedAllFonts=true - $p ;;
        *) echo "PDF export not supported for this file type..."
    esac

    title=$(sed -z -e "s/.*<h1[^>]*>//g" -e "s/<\/h1>.*//g" $o)

    article_list+="<a href=\"$adir/$id.html\">$title</a></br>"

    c=$(($c+1))

    # Strip all the unneeded stuff

    if [ $keep_styles = true ]; then
        sed -zi -e "s/.*<style[^>]*>/<style>/" \
                -e "s/<\/style>.*<body[^>]*>/<\/style>/" \
                -e "s/<\/body>.*//" $o
    else
        sed -zi -e "s/.*<body[^>]*>//" -e "s/<\/body>.*//" $o
    fi

    echo "<div class=\"article\">$(cat $o)</div>" > $o

    # Escape some characters for sed
    escaped=$title
    escaped=${escaped//\\/\\\\}
    escaped=${escaped//\//\\/}
    escaped=${escaped//\&/\\\&}

    sed -e "s/{title}/$escaped/" \
        -e "/{article}/{
                s/{article}//
                r $o
            }" \
        article_template.html > $adir/$id.html

    if [ $c -le $recent_articles_max ]; then
        cat $o >> $bdir/recent_articles.html
    fi

    if [[ "$IFS${known_ids[*]}$IFS" =~ "$IFS$id$IFS" ]]; then
        echo "ID \`$id' already used!"
        exit 1
    fi

    known_ids+=($id)
done

# Generate the welcome text.
preconv welcome.ms | groff -mwww -ms -Thtml > $bdir/welcome.html

sed -zi -e "s/.*<body[^>]*>//" -e "s/<\/body>.*//" -e "s/align=\"center\"//g" \
        -e "s/style=\"[^\"]*\"//" $bdir/welcome.html

echo $article_list

# Do not generate index.html if $strip_html_structure is disabled, as it would
# produce invalid html.

IFS=""

# Escape some characters of the article list for sed
article_list=${article_list//\\/\\\\}
article_list=${article_list//\//\\/}
article_list=${article_list//\&/\\\&}

if [ $strip_html_structure = true ]; then
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
fi

unset IFS
