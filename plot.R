png(filename='chrome.png',width=728,height=400)

trace <- read.table('trace.tsv',header=T)

time <- trace$ms/1000
cpu <- trace$cpu_load_perc
ram <- trace$res_mem_kb/2^10
reads <- trace$read_b/2^20
writes <- trace$write_b/2^20

colors <- c('#0099cc','#9933cc','#669900','#ff8800')

plot.new()
title('Chrome cold-start')
par(mar=c(5,5,5,5))
box()

xlim <- c(0,100)
mtext("Time (s)",side=1,line=3)

# RAM, reads, writes
plot.window(xlim,ylim=c(0,max(ram,reads,writes)))
lines(time,ram,col=colors[1])
lines(time,reads,col=colors[2])
lines(time,writes,col=colors[3])
mtext("MB",side=2,line=3)
axis(2)

# CPU
plot.window(xlim,ylim=c(0,100))
lines(time,cpu,col=colors[4])
mtext("CPU load (%)",side=4,line=3)
axis(4)

axis(1)

# legend
legend('topleft',
       legend=c("RAM (MB)","Reads (MB)","Writes (MB)","CPU (%)"),
       col=colors,lty=c('solid','solid','solid','solid'))
