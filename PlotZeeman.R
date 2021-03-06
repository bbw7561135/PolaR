# StokeSpec
# usage: Rscript StokesSpec [Scan.Rdata file name] [SPEC.Rdata file name] [WG.Rdata file name] [BP file name]
#
#-------- Parse command-line arguments
parseArg <- function( args ){
    argNum <- length(args)
    lineFreq <- c(1.6, 1.7)
    plotFreq <- c(1.6, 1.7)
    smoothCH <- 256
    bunchCH  <- 32
    restFreq  <- 45379.033000    # CCS rest frequency, [MHz]
    trackFreq <- 2.0             # Tracking frequency, [MHz]
    trackVel  <- 5.9             # Tracking velocity,  [km/s]
    for( index in 1:argNum ){
        if(substr(args[index], 1,2) == "-l"){ lineFreq[1] <- as.numeric(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-L"){ lineFreq[2] <- as.numeric(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-p"){ plotFreq[1] <- as.numeric(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-P"){ plotFreq[2] <- as.numeric(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-r"){ restFreq <- as.numeric(substring(args[index], 3))}   # Tracking  Frequency
        if(substr(args[index], 1,2) == "-t"){ trackFreq <- as.numeric(substring(args[index], 3))}     # Reference Frequency
        if(substr(args[index], 1,2) == "-v"){ trackVel  <- as.numeric(substring(args[index], 3))}     # Reference Frequency
        if(substr(args[index], 1,2) == "-I"){ IF <- as.integer(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-S"){ srcName <- substring(args[index], 3)}
        if(substr(args[index], 1,2) == "-s"){ smoothCH <- as.integer(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-b"){ bunchCH  <- as.integer(substring(args[index], 3))}
        if(substr(args[index], 1,2) == "-M"){ lineName <- substring(args[index], 3)}
    }
    fileName <- args[argNum]
    return( list(lineFreq = lineFreq, plotFreq = plotFreq, restFreq = restFreq, trackFreq = trackFreq, trackVel = trackVel, srcName = srcName, lineName = lineName, fileName = fileName, IF = IF, smoothCH = smoothCH, bunchCH = bunchCH) )
}

RPATH <- '~/Programs/PolaR'
FuncList <- c('PolariCalib')
source(sprintf('%s/loadModule.R', RPATH))
library(RCurl)

funcNum <- length(FuncList)
for( index in 1:funcNum){
    URL <- sprintf("https://raw.githubusercontent.com/kamenoseiji/PolaR/master/%s.R", FuncList[index])
    Err <- try( eval(parse(text = getURL(URL, ssl.verifypeer = FALSE))), silent=FALSE)
}
if(class(Err) == "try-error"){ loadLocal( RPATH, FuncList ) }

setwd('.')
#-------- Load Spec and Scan data
args <- parseArg(commandArgs(trailingOnly = T))
setwd('.')
load(args$fileName)	 #Load Stokes file
PDFfilename <- sprintf("%s.Zeeman.%d.pdf", strsplit(args$fileName, "\\.")[[1]][1], args$IF)
chNum <- length(StokesI02)
freq <- (0:(chNum-1))/chNum* 4.0	# MHz
chSep <- 4.0 / chNum
veloc0 <- (args$trackFreq - freq) / args$restFreq * 299792.458 + args$trackVel
SDrange <- 8193:16384
# JyK <- 3.0 # Jy per K
JyK <- 1.0 # Jy per K
if(args$IF == 2){
    StokesI <- StokesI13* JyK
    StokesQ <- StokesQ13* JyK
    StokesU <- StokesU13* JyK
    StokesV <- StokesV13* JyK
} else {
    StokesI <- StokesI02* JyK
    StokesQ <- StokesQ02* JyK
    StokesU <- StokesU02* JyK
    StokesV <- StokesV02* JyK
}
#-------- Plot Stokes I 
pdf(PDFfilename)
plotFreq <- args$plotFreq # range in MHz
lineFreq <- args$lineFreq
baseFreq <- c(plotFreq[1], lineFreq[1], lineFreq[2], plotFreq[2])
plotRange <- which.min(abs(freq - plotFreq[1])):which.min(abs(freq - plotFreq[2]))
lineRange <- which.min(abs(freq[plotRange] - lineFreq[1])):which.min(abs(freq[plotRange] - lineFreq[2]))
baseRange <- c(which.min(abs(freq - baseFreq[1])):which.min(abs(freq - baseFreq[2])), which.min(abs(freq - baseFreq[3])):which.min(abs(freq - baseFreq[4])))
knotNum <- floor(length(plotRange) / args$smoothCH)
weight <- rep(1.0, length(plotRange))
plotBunch <- args$bunchCH
StokesI <- StokesI - mean(StokesI[baseRange])
fitStokesI <- smooth.spline(freq[plotRange], StokesI[plotRange], w=weight, all.knots=F, nknots=4*knotNum)
fitStokesQ <- smooth.spline(freq[plotRange], StokesQ[plotRange], w=weight, all.knots=F, nknots=4*knotNum)
fitStokesU <- smooth.spline(freq[plotRange], StokesU[plotRange], w=weight, all.knots=F, nknots=4*knotNum)
predStokesV <- predict(fitStokesI, (freq[plotRange] + 0.5e-6))$y - predict(fitStokesI, (freq[plotRange] - 0.5e-6))$y
predStokesI <- predict(fitStokesI, freq[plotRange])$y
predStokesQ <- predict(fitStokesQ, freq[plotRange])$y
predStokesU <- predict(fitStokesU, freq[plotRange])$y
fitBunch  <- 8
cols   <- c('black', 'blue', 'green')
labels <- c('I', 'Q', 'U')
#plot( freq[plotRange], StokesI[plotRange], type='l', xlab='Frequency [MHz]', ylab='Stokes I [K]', main=sprintf('%s %s', args$srcName, args$lineName))
#lines( bunch_vec(freq[plotRange],plotBunch)-0.5*plotBunch*chSep, bunch_vec(StokesQ[plotRange], plotBunch), type='s', col=cols[2])
#lines( bunch_vec(freq[plotRange],plotBunch)-0.5*plotBunch*chSep, bunch_vec(StokesU[plotRange], plotBunch), type='s', col=cols[3])
#lines( bunch_vec(freq[plotRange], fitBunch), bunch_vec(predStokesI, fitBunch), col='orange')
plot( veloc0[plotRange], StokesI[plotRange], type='l', xlab='LSR Velocity [km/s]', ylab='Stokes I [Jy]', main=sprintf('%s %s', args$srcName, args$lineName))
lines( bunch_vec(veloc0[plotRange],plotBunch)-0.5*plotBunch*chSep, bunch_vec(StokesQ[plotRange], plotBunch), type='s', col=cols[2])
lines( bunch_vec(veloc0[plotRange],plotBunch)-0.5*plotBunch*chSep, bunch_vec(StokesU[plotRange], plotBunch), type='s', col=cols[3])
lines( bunch_vec(veloc0[plotRange], fitBunch), bunch_vec(predStokesI, fitBunch), col='orange')
legend("topleft", legend=labels, col=cols, lty=rep(1,3))
abline(h=0, col='gray')
cat(sprintf("Peak I = %5.2f +- %5.3f K\n", max(bunch_vec(predStokesI, fitBunch)), sd( StokesI[baseRange] )/sqrt(plotBunch) ))
#-------- Plot dI/df 
#plot(freq[plotRange], predStokesV, type='l', xlab='Frequency [MHz]', ylab='dI/df [K/Hz]', main=sprintf('%s %s', args$srcName, args$lineName), col='red')
plot(veloc0[plotRange], predStokesV, type='l', xlab='LSR Velocity [km/s]', ylab='dI/df [Jy/Hz]', main=sprintf('%s %s', args$srcName, args$lineName), col='red')
maxDif <- max(predStokesV); maxVeloc <- veloc0[plotRange[which.max(predStokesV)]]; cat(sprintf('%8.5e K/Hz @ %5.3f km/s\n', maxDif, maxVeloc))
minDif <- min(predStokesV); minVeloc <- veloc0[plotRange[which.min(predStokesV)]]; cat(sprintf('%8.5e K/Hz @ %5.3f km/s\n', minDif, minVeloc)) 
text( maxVeloc, maxDif, sprintf('%5.2e K/Hz at %4.2f km/s', maxDif, maxVeloc), cex=0.3, pos=4)
text( minVeloc, minDif, sprintf('%5.2e K/Hz at %4.2f km/s', minDif, minVeloc), cex=0.3, pos=4)
abline(h=0)
#-------- Plot Stokes V 
#err <- sd(StokesV02[SDrange]) / sqrt(plotBunch)
err <- sd(StokesV[SDrange]) / sqrt(plotBunch)
fit <- lm(formula=z~1+x+y, data=data.frame(x=predStokesV[lineRange], y=predStokesI[lineRange], z=StokesV[plotRange[lineRange]]))
summary(fit)
#plotX <- bunch_vec(freq[plotRange], plotBunch)
plotX <- bunch_vec(veloc0[plotRange], plotBunch)
plotY <- bunch_vec(StokesV[plotRange] - fit$coefficients[1] - fit$coefficients[3]* predStokesI, plotBunch)
Ymax <- max(abs(plotY))
plot( plotX, plotY , pch=20, ylim=c(-2.0*Ymax, 2.0*Ymax), xlab='LSR Velocity [km/s]', ylab='Stokes V [Jy]', main=sprintf('%s %s', args$srcName, args$lineName))
arrows( plotX, plotY - err, plotX, plotY + err, angle=90, length=0)
#lines( bunch_vec(freq[plotRange], fitBunch), bunch_vec(predStokesV*fit$coefficients[2], fitBunch), col='red')
lines( bunch_vec(veloc0[plotRange], fitBunch), bunch_vec(predStokesV*fit$coefficients[2], fitBunch), col='red')
legend(min(veloc0[plotRange]), 1.9*Ymax, legend=sprintf('Zeeman Shift = %5.1f ± %4.1f Hz', fit[[1]][2], summary(fit)[[4]][5]))

DF <- data.frame(veloc = veloc0[plotRange], I = StokesI[plotRange], Q = StokesQ[plotRange], U = StokesU[plotRange], V = StokesV[plotRange])
write.table( format(DF, digits=6), file=sprintf("%s.Zeeman.%d.txt", strsplit(args$fileName, "\\.")[[1]][1], args$IF), quote=F, col.names=T, row.names=F)
dev.off()
