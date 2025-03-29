awk -v x="$memory_used" -v y="$memory_total" 'BEGIN { printf "GPU %.1f%",(x / y) * 100 }'
