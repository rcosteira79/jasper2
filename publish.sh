#!/bin/sh

# Very simple script to automate deployment to the actual website repo (rcosteira79.github.io)

set /p commitMessage=Commit Description: 

if [ -d "./_site" ]
then
  rm -rf "./_site" 
fi

echo Building with Jekyll...
set JEKYLL_ENV=production
bundle exec jekyll build

echo Copying output to website repo...

# exclude README.md and the pictures with "original" text in name.
# I want the README.md that's already on the site repo, and the original pictures are not necessary
rsync -avr --exclude=".DS_Store" --exclude="README.md" --exclude="assets/images/*-original.*" --exclude="publish.bat" --exclude="publish.sh" "./_site/" "../rcosteira79.github.io"

echo Done. Walking into the website\'s directory...

cd "../rcosteira79.github.io"

echo Commiting!

#git add .

#git commit -m "%commitMessage%"

#git push

echo All done. Go and see the website on https://ricardocosteira.com :\)
