# read elegiacs
elegiacs <- read.table(file.path('tables', '20l-full'), header=T, sep="\t")

# drop columns other than sampleid, meter, wl
elegiacs <- elegiacs[, c(1, 4, 5)]
elegiacs$meter[elegiacs$meter == 0] <- 'el_hex'
elegiacs$meter[elegiacs$meter == 1] <- 'el_pent'
elegiacs$meter[elegiacs$meter == 2] <- 'elegiacs'

# read stichic hexameters
stichic <- read.table(file.path('tables', 'stichic'), header=T, sep="\t")

# drop columns other than sampleid, meter, wl
stichic <- stichic[, c(1, 4, 5)]
stichic$meter <- 'hexameters'

verses <- rbind(elegiacs, stichic)

# draw 2-way boxplot
with(verses[verses$meter %in% c('hexameters', 'elegiacs'),], 
     boxplot(
       wl ~ meter,
       ylab = "wordlength (chars)"
     ))


# draw boxplot
with(verses[verses$meter != 'elegiacs',], 
     boxplot(
       wl ~ meter,
       ylab = "wordlength (chars)"
))
