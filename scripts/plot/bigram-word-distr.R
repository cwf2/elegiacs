
bigrams = c("er", "is", "re", "es", "um")

for (author in c("catullus", "propertius", "tibullus", "ovid", "martial")) {

	maxcount = 0
	maxrank = 0

	for (bigram in bigrams) {
	
		my.data <- read.table(file=paste("/Users/chris/elegiacs/data/word-count/", bigram, "~", author, sep=""))
	
		maxcount = max(c(maxcount, max(my.data[,2])))
		maxrank = max(c(maxrank, nrow(my.data)))
	}

	x11(title=author)

	plot (log(1:nrow(my.data)), log(my.data[,2]), type="l", main=author, xlab="log rank", ylab="log count", xlim=c(0,log(maxrank)), ylim=c(0,log(maxcount)))


	
	for (i in 1:5) {

		bigram = bigrams[i]

		my.data <- read.table(file=paste("/Users/chris/elegiacs/data/word-count/", bigram, "~", author, sep=""))
	
		lines (log(1:nrow(my.data)), log(my.data[,2]), col=i)	
	}

	legend(x="topright", legend=bigrams, col=c(1:5), lw=1)
}
