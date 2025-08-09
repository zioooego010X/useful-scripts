#!/bin/bash

# Super Bug Bounty Crawler by Ziyad & Ritsa 💀

usage() {
  echo "Usage:"
  echo "  $0 -u <https://site.com>   # Single target"
  echo "  $0 -l <list.txt>           # List of targets"
  exit 1
}

scan_target() {
  target=$1
  clean=$(echo "$target" | sed 's/https\?:\/\///' | sed 's/[^a-zA-Z0-9]/_/g')
  outdir="recon-$clean"
  mkdir -p "$outdir"

  echo "[*] Scanning $target → Output: $outdir"

  echo "[+] katana..."
  katana -u "$target" -jc -jsl -xhr -kf  -j  -silent -o "$outdir/katana.txt"

  echo "[+] hakrawler..."
  echo "$target" | hakrawler -depth 3 -plain -js -subs > "$outdir/hakrawler.txt"

  echo "[+] gau..."
  echo "$target" | gau > "$outdir/gau.txt"

  echo "[+] waybackurls..."
  echo "$target" | waybackurls > "$outdir/waybackurls.txt"

  echo "[+] paramspider..."
  paramspider -d "$target" --exclude woff,ttf,png,jpg -o "$outdir/paramspider.txt" > /dev/null 2>&1

  echo "[+] getJS..."
  getJS --url "$target" --complete > "$outdir/getJS.txt"

  echo "[+] linkfinder..."
  mkdir -p "$outdir/linkfinder"
  find "$outdir/jscollector/" -name "*.js" | while read jsfile; do
    linkfinder -i "$jsfile" -o cli >> "$outdir/linkfinder/results.txt"
  done

  echo "[+] arjun (hidden parameters)..."
  arjun -u "$target" --passive -oT "$outdir/arjun.txt" > /dev/null 2>&1

  echo "[+] Combine all results..."
  cat "$outdir/"*.txt "$outdir"/linkfinder/*.txt 2>/dev/null | sort -u > "$outdir/all-urls.txt"

  echo "[+] Filtering live URLs..."
  httpx -silent -l "$outdir/all-urls.txt" -mc 200,403,401 -t 50 > "$outdir/live-urls.txt"

  echo "[✔] Done for $target — Links: $(wc -l < "$outdir/all-urls.txt") | Live: $(wc -l < "$outdir/live-urls.txt")"
}

### MAIN LOGIC ###
if [[ "$1" == "-u" && -n "$2" ]]; then
  scan_target "$2"
elif [[ "$1" == "-l" && -f "$2" ]]; then
  while read -r url; do
    [[ -z "$url" || "$url" == \#* ]] && continue
    scan_target "$url"
  done < "$2"
else
  usage
fi
