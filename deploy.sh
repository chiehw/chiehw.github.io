git add . && git commit -m "update" && git push

hexo g
# CNAME
echo "chieh.wang" >> public/CNAME
# Deploy
hexo clean && hexo deploy