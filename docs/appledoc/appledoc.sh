#!/bin/bash

ME="`dirname \"$0\"`"

appledoc --project-name NSRails --project-company "Dan Hassin" --company-id com.danhassin --output $ME/.. --ignore *.m --no-install-docset --no-repeat -h -d --keep-intermediate-files --index-desc $ME/index.md --explicit-crossref --include $ME/img $ME/../../nsrails/Source

#move the generated docset into the install-in-xcode applescript bundle
rm -r $ME/../install\ in\ xcode.app/Contents/Resources/com.danhassin.NSRails.docset
mv $ME/../docset $ME/../install\ in\ xcode.app/Contents/Resources/com.danhassin.NSRails.docset
