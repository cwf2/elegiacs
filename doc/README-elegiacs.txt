Notes on elegiac texts.

1. Clean up Perseus texts

	The original texts downloaded from Perseus are in the directory
		texts/perseus
	My simplified texts are in
		texts/simple
		
	Major differences in the simplified texts:
		<div1> and <div2> are both simplified to <div>
		every line is enclosed within <l> tags
		every <l> has its own line number
		every <l> contins only text
		pretty everything else from the Perseus file is removed.
		
	Each text is cleaned by its own perl script, since each of the Perseus
	files seemed to have its own idiosyncrasies.  These perl scripts are in
		scripts/parse
	Each one expects to find a certain file in texts/perseus but you can
	also specify an input file as an argument.
	
	For a couple of authors I'm only using the subset of poems that are
	in elegiac couplets.  These are:
		catullus.elegies.xml	--	only poems 65-116
		tibullus.elegies.xml	--  everything except the hexameter poem
		martial.elegies.xml		--	see martial notes.txt
	
2. Create a set of samples from the text files

	Sampling scripts are in
		scripts/sample

	Right now there are two:
		20l-full.pl
		20l-fair.pl
	
	Both create 20-line samples.  Both use only texts in elegiac couplets
	by default.  That means (in the texts/simple directory)
		catullus.elegies.xml
		tibullus.elegies.xml
		propertius.xml
		ovid.amores.xml
		ovid.ars.xml
		ovid.remedia.xml
		ovid.heroides.xml
		ovid.fasti.xml
		ovid.tristia.xml
		ovid.ex_ponto.xml
		martial.elegies.xml
		
	Three sets of samples are created
		the "h" series is made up of only hexameter lines
		the "p" series is made up of only pentameter lines
		the "m" series is made up of a mixture of both
		
	The "full" sampler uses all the texts.  It starts at the beginning and
	saves every 20 consecutive lines to a separate sample.  A little nub, 
	less than 20 lines, left over at the end of each text is discarded.
	
	The "fair" sampler only 320 lines for the h and p series, 640 for the m.
	This is the maximum size that allows an equal number of lines to be taken
	from every author.
	For any author with multiple texts, they're all put together first, and then
	randomized.  So Ovid's samples are drawn from across all his works.
		NB: The order of the lines is randomized even for authors with only one 
		work, and even for Catullus, whose whole elegiac corpus is only 640 lines.

	The samples are stored in a separate directory, elegiacs/data, created in
	your home directory.  This has to be outside the Dropbox folder, otherwise
	Dropbox tries to back up hundreds of samples.  It would perhaps be better to
	share using Subversion rather than Dropbox, since then we could specify certain
	directories shouldn't be backed up.
	
	[24.01.2018] Took project out of Dropbox and started a git repo. `data` is now
	stored locally, and included in `.gitignore`.
	
3. Quantify the features we're interested in, and save the results to a table.
	Right now I only have one script, it's called word-length.pl and it's in
		scripts/measure
	It just measures the average word length for each 20l sample.
	You have to specify the dataset you want to measure as an argument--this means
	the subdirectory of $home/elegiacs/data where the samples are stored.
	The choices are 20l-full and 20l-fair, for now (assuming you've run both
	scripts in step 2).
	
	The results are stored in the directory
		tables
