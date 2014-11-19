# This is the default metric group, some of most common system metrics are
# defined here. This file is loaded by default. Metric functions should be
# simple and lightweight shell commands and under no circumstances they should
# fork backgroud processes or introduce delay. Metric names should be
# self-descriptive and should include its unit of measure when not clear by the
# name itself.

read_b() { sed -n 's/^read_bytes: //p' /proc/$pid/io; }

write_b() { sed -n 's/^write_bytes: //p' /proc/$pid/io; }

buf_read_b() { sed -n 's/^rchar: //p' /proc/$pid/io; }

buf_write_b() { sed -n 's/^wchar: //p' /proc/$pid/io; }

core_count() { nproc; }

cpu_load_perc() { command ps -p $pid -o pcpu=; }

virt_mem_kb() { command ps -p $pid -o vsz=; }

res_mem_kb() { command ps -p $pid -o rss=; }

swap_mem_kb() { awk '/^Swap:/ {sum+=$2} END {print sum}' /proc/$pid/smaps; }

total_mem_kb() { awk '/^MemTotal:/ {print $2}' /proc/meminfo; }

used_swap_kb() { awk '/^SwapCached:/ {print $2}' /proc/meminfo; }

total_swap_kb() { awk '/^SwapTotal:/ {print $2}' /proc/meminfo; }
