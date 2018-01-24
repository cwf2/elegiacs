my.data <- read.table("tables/20l-fair", header=TRUE)

with(my.data[my.data$meter<2,], plot(score, col=author+1, pch=meter))