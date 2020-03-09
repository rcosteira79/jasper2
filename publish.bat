@echo off
REM Very simple script to automate deployment to the actual website repo (rcosteira79.github.io)

set /p commitMessage=Commit Description: 

if exist "./_site" @RD /S /Q "./_site"

echo Building with Jekyll...
set JEKYLL_ENV=production
call bundle exec jekyll build

echo Copying output to website repo...

REM exclude README.md and the pictures with "original" text in name.
REM I want the README.md that's already on the site repo, and the pictures are not necessary
robocopy "./_site" "../rcosteira79.github.io" /e /njh /njs /ndl /nc /ns /np /nfl /xf "README.md" "*-original.*" "publish.bat" "publish.sh"

echo Done. Walking into the website's directory...

cd "../rcosteira79.github.io"

echo Commiting!

git add .

git commit -m "%commitMessage%"

git push

echo All done. Go and see the website on https://ricardocosteira.com :)