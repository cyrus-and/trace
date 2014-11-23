# This is the default metric group, some of most common system metrics are
# defined here. This file is loaded by default. Metric functions should be
# simple and lightweight shell commands and under no circumstances they should
# fork backgroud processes or introduce delay. Metric names should be
# self-descriptive and should include its unit of measure when not clear by the
# name itself, Also they must start with "m_", though when referenced from the
# command line this part must be omitted.

m_read_b() { sed -n 's/^read_bytes: //p' /proc/$pid/io; }

m_write_b() { sed -n 's/^write_bytes: //p' /proc/$pid/io; }

m_buf_read_b() { sed -n 's/^rchar: //p' /proc/$pid/io; }

m_buf_write_b() { sed -n 's/^wchar: //p' /proc/$pid/io; }

m_core_count() { nproc; }

m_cpu_load_perc() { command ps -p $pid -o pcpu=; }

m_virt_mem_kb() { command ps -p $pid -o vsz=; }

m_res_mem_kb() { command ps -p $pid -o rss=; }

m_swap_mem_kb() { awk '/^Swap:/ {sum+=$2} END {print sum}' /proc/$pid/smaps; }

m_total_mem_kb() { awk '/^MemTotal:/ {print $2}' /proc/meminfo; }

m_free_mem_kb() { awk '/^MemFree:/ {print $2}' /proc/meminfo; }

m_total_swap_kb() { awk '/^SwapTotal:/ {print $2}' /proc/meminfo; }

m_free_swap_kb() { awk '/^SwapFree:/ {print $2}' /proc/meminfo; }

m_total_net_tx_b() { awk '/^.*:/ && $1 != "lo:" {sum+=$2} END {print sum}' /proc/net/dev; }

m_total_net_rx_b() { awk '/^.*:/ && $1 != "lo:" {sum+=$10} END {print sum}' /proc/net/dev; }
