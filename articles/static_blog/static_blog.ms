.fam N

.NHR

.TL
Making my website statically generated

.AU
Mibi88

.ND
08/11/2025

.PP
GitHub Pages imposes a big restriction on how pages can behave as they need to
be static, which can be quite inconvenient. To make my website easier to modify
I was using some JS to load the articles in the main page. However, it was
therefore limiting it to browsers supporting\~/\~with JS enabled, and it isn't
very scalable, as when there will be more and more articles, the website will
have more and more articles to fetch and display. it was also quite annoying to
write new articles or just update the project list as I had to write HTML, and
I have an obsession of wrapping my code on 80 columns :D (actually 79) which
doesn't work very well when writing HTML.

.PP
That's why I wanted to generate my website statically with a script. I wanted 
to write an article about how I struggled trying to fix my computer's cable 
management, but I decided to fix my website first. Originally I wanted to use 
python and something else like markdown, but finally I used
.CW "bash"\&,
.CW sed
and
.CW groff
(it's a bit cooler :D). I'm also calling LyX to convert the older articles. My 
script is still a bit messy, but it works nicely. It loads the lists of 
articles and ``projects'' (the sections where all my projects are listed by 
category, e.g., ``Games'' or ``Libraries'', I don't really know how to call 
them), where the paths and the IDs (for articles) or the titles (for 
``projects'') are separated by semicolons. The most recent articles are listed 
first. My script then walks through these lists and generates the HTML code 
with the appropriate tool. Then I use
.CW sed
a bunch to remove all the superfluous HTML that would make the generated HTML 
invalid (when viewing the source code via Firefox, it seems to be unhappy with 
the header and footer, but that's because my template HTML code itself is 
incorrect \(em I'm not writing HTML very often \(em and I didn't know that
.CW <header>
and
.CW <footer>
must be inside
.CW <body>\&).
Then I use
.CW sed
again to replace
.CW {<name>}
tags with the appropriate generated HTML, such as
.CW {article_list}
which gets replaced with a list of links to all the articles. I should run
.CW sed
over the articles and ``projects'' as well to replace curly braces with an 
escape sequence to avoid such tags to get replaced in the articles' content, 
but I'll fix that later. I'm also generating PDFs of the articles because I can 
(lol), but I don't include them in the git repo. I've already an idea of a 
little Easter egg that I could add with a little bit of JS, but I'll do it 
later.

.PP
So that's how I statically generate my website without using a premade
solution. In the end it took me way longer than I expected, but it was quite
fun!
.CW roff
is fascinating, maybe I'll code my own implementation of it at some point...
