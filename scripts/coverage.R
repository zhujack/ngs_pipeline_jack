files <- list.files(pattern="coverage.txt$")

cov <- list()
cov_cumul <- list()
for (i in 1:length(files)) {
    cov[[i]] <- read.table(files[i])
    cov_cumul[[i]] <- 1-cumsum(cov[[i]][,5])
}
labs <- paste("", gsub("Sample_|\\.coverage\\.txt", "", files, perl=TRUE), sep="")

library(RColorBrewer)
cols <- brewer.pal(length(cov)+1, "Dark2")

# Save the graph to a file
png("exome-coverage-plots.png", h=1000, w=1000, pointsize=20)

# Create plot area, but do not plot anything. Add gridlines and axis labels.
par(las=2)
plot(
	cov[[1]][2:401, 2], 
	cov_cumul[[1]][1:400], 
	type='n', 
	xaxs="i",
	yaxs="i",
	xlab="Coverage", 
	ylab="Fraction of capture target bases \u2265 depth", 
	ylim=c(0,1.001),
	las=1,
	xlim=c(-2,400),
	main="Target Region Coverage"
	)
abline(v =c(20,50, 80, 100, 200), col = "darkgray")
abline(h =c(0.50, 0.80, 0.90), col = "darkgray")

# Actually plot the data for each of the alignments (stored in the lists).
for (i in 1:length(cov)){
	points(
		cov[[i]][2:401, 2], cov_cumul[[i]][1:400], type='l', lwd=3, col=cols[i]
	)
}
box()
# Add a legend using the nice sample labeles rather than the full filenames.
legend("topright", legend=labs, col=cols, lty=1, lwd=4)

dev.off()