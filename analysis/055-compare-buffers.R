library(ggplot2)
library(reshape2)
library(BEST)

## Read our datasets
areas_wide <- read.csv("./results/buffer_areas.csv")
symdiffs_wide <- read.csv("./results/buffer_symdiffs.csv")

## Convert to tidy/long format and ft^2 -> km^2
ft2tokm2 <- function(x) x * 9.2903e-8  
areas <- melt(areas_wide, value.name="sqft", variable.name="type", id.vars=c("id"))
areas$km2 <- ft2tokm2(areas$sqft)
symdiffs <- melt(symdiffs_wide, value.name="sqft", variable.name="type", id.vars=c("id"))
symdiffs$km2 <- ft2tokm2(symdiffs$sqft)

## Descriptive density plots of areas and symmetric differences
area_dens <- ggplot(areas, aes(x=km2, color=type, linetype=type)) +
  scale_color_brewer(type="qual", palette=2) +
  geom_density() + theme_bw()
ggsave("./results/area_dens.pdf", width=5, height=2.5)

symdiff_dens <- ggplot(symdiffs, aes(x=km2)) +
  geom_density() + theme_bw()
ggsave("./results/symdiff_dens.pdf", width=5, height=2.5)

## Statistically compare areas of pg buffers and esri round ended
## buffers using BEST
best_areas_pg_esr <- BESTmcmc(y1=ft2tokm2(areas_wide$postgis),
                              y2=ft2tokm2(areas_wide$esri))

## Power analysis, takes quite a while to run
## bpwr_areas_pg_esr <- BESTpower(best_areas_pg_esr,
##                                N1=length(areas_wide$postgis),
##                                N2=length(areas_wide$esri_round), 
##                                ROPEm=c(-0.0314,0.0314),
##                                maxHDIWm=1.0, nRep=1000) 

## Plots from BEST
pdf("./results/best_areas_pg_esr_mean.pdf", width=8, height=4)
plot(best_areas_pg_esr, "mean")
dev.off()

pdf("./results/best_areas_pg_esr_sd.pdf", width=8, height=4)
plot(best_areas_pg_esr, "sd")
dev.off()

pdf("./results/best_areas_pg_esr_effect.pdf", width=8, height=4)
plot(best_areas_pg_esr, "effect")
dev.off()

pdf("./results/best_areas_pg_esr_nu.pdf", width=8, height=4)
plot(best_areas_pg_esr, "nu")
dev.off()

pdf("./results/best_areas_pg_esr.pdf", width=8.5, height=11)
plotAll(best_areas_pg_esr)
dev.off()
