Get-ChildItem * -Include *.~* -Recurse | Remove-Item
Get-ChildItem * -Include *~*.* -Recurse | Remove-Item
Get-ChildItem * -Include *.lnk -Recurse | Remove-Item
