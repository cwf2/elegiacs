stichic <- read.table("tables/stichic",  header=TRUE)
elegiac <- read.table("tables/20l-fair", header=TRUE)

master  <- rbind(stichic, elegiac)

dates   <- read.table("tables/dates")
dates   <- setNames(dates$V2, as.vector(dates$V1))
master  <- cbind(master, date=dates[master$author])

png("plots/wl.vs.meter.png")
with(master, boxplot(wl/wc ~ meter, ylab="mean word length"))
dev.off()

png("plots/wl.vs.meter.catullus.png")
with(master[master$author=='catullus',], boxplot(wl/wc ~ meter, ylab="mean word length", main="catullus"))
dev.off()

png("plots/wl.vs.meter.ovid.png")
with(master[master$author=='ovid',], boxplot(wl/wc ~ meter, ylab="mean word length", main="ovid"))
dev.off()

with(master, plot(wl/20, wc/20, xlab="characters/line", ylab="words/line", col=meter, pch=as.numeric(meter)))
legend("topleft", legend=levels(master$meter), col=unique(sort(as.numeric(master$meter))), pch=unique(sort(as.numeric(master$meter))))


write.table(master, file="tables/master", quote=FALSE, row.names=FALSE)