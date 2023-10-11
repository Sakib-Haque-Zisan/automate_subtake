#!/bin/bash
url=$1
if [ ! -d "$url" ];then
mkdir $url

fi

if [ ! -d "$url/recon" ];then
mkdir $url/recon 

fi 
if [ ! -d "$url/recon/scans" ];then
mkdir $url/recon/scans

fi 
if [ ! -d "$url/recon/httprobe" ];then
mkdir $url/recon/httprobe


fi 
if [ ! -d "$url/recon/sub_takeovers" ];then
mkdir $url/recon/sub_takeovers

fi 
if [ ! -d "$url/recon/wayback" ];then
mkdir $url/recon/wayback

fi 
if [ ! -d "$url/recon/params" ];then
mkdir $url/recon/params

fi 
if [ ! -d "$url/recon/extensions" ];then
mkdir $url/recon/extensions

fi 
if [ ! -f "$url/recon/httprobe/alive.txt" ];then
touch $url/recon/httprobe/alive.txt

fi 
if [ ! -f "$url/recon/final.txt" ];then
touch $url/recon/final.txt

fi 
echo "[+] Hunting Subdomains with Assetfinder.."

assetfinder $url >> $url/recon/assets.txt
cat $url/recon/assets.txt | grep $1 >> $url/recon/final.txt
rm $url/recon/assets.txt 

echo "[+] Finding Alive Domains with httprobe..."
cat $url/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' | tee -a $url/recon/httprobe/a.txt
sort -u $url/recon/httprobe/a.txt > $url/recon/httprobe/alive.txt
rm $url/recon/httprobe/a.txt 

echo "[+] Checking Posiible Subdomains to Takeover...." 

if [ ! -f "$url/recon/sub_takeovers/sub_takeovers.txt" ];then
touch $url/recon/sub_takeovers/sub_takeovers.txt

fi

subjack -w $url/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/blob/master/fingerprints.json -v 3 -o
$url/recon/sub_takeovers/sub_takeovers.txt 

echo "[+] Scanning for Open Ports..."
nmap -iL $url/recon/httprobe/alive.txt -T4 -oA $url/recon/scans/scanned.txt

echo "[+] Scraping wayback data..."
cat $url/recon/final.txt | waybackurls >> $url/recon/wayback/wayback_output.txt
sort -u $url/recon/wayback/wayback_output.txt 

echo "[+] Compiling all possible params found in wayback data..."
cat $url/recon/wayback/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $url/recon/wayback/params/wayback_params.txt 

for line in $(cat $url/recon/wayback/params/wayback_params.txt);do echo $line'=';done

echo "[+] Pulling and Compiling js/php/aspx/jsp/json files wayback output..."
for line in $(cat $url/recon/wayback/wayback_output.txt);do 
ext="${line##*.}"
if [[ "$ext" == "js" ]]; then
echo $line >> $url/recon/wayback/extensions/js1.txt
sort -u $url/recon/wayback/extensions/js1.txt >> $url/recon/wayback/extensions/js.txt

fi
if [[ "$ext" == "html" ]]; then
echo $line >> $url/recon/wayback/extensions/jsp1.txt
sort -u $url/recon/wayback/extensions/jsp1.txt >> $url/recon/wayback/extensions/jsp1.txt

fi
if [[ "$ext" == "json" ]]; then
echo $line >> $url/recon/wayback/extensions/json1.txt
sort -u $url/recon/wayback/extensions/json1.txt >> $url/recon/wayback/extensions/json.txt

fi
if [[ "$ext" == "php"  ]]; then
echo $line >> $url/recon/wayback/extensions/php1.txt
sort -u $url/recon/wayback/extensions/php1.txt >> $url/recon/wayback/extensions/php.txt

fi
if [[ "$ext" == "aspx" ]]; then
echo $line >> $url/recon/wayback/extensions/aspx1.txt
sort -u $url/recon/wayback/extensions/aspx1.txt >> $url/recon/wayback/extensions/aspx.txt

fi

done

rm $url/recon/wayback/extensions/js1.txt
rm $url/recon/wayback/extensions/jsp1.txt
rm $url/recon/wayback/extensions/json1.txt
rm $url/recon/wayback/extensions/php1.txt
rm $url/recon/wayback/extensions/aspx1.txt
