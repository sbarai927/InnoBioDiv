# Load required library for plotting
library(ggplot2)

# Read the combined dataset (exported from Excel) with growth and root parameters
data <- read.csv("InnoBioDiv_data.csv")  # file contains Genotype, Microbe, Temperature, and measurement columns

# Convert relevant columns to factors with proper ordering
data$Genotype <- factor(data$Genotype, levels = c("WT", "symrk"))
data$Microbe  <- factor(data$Microbe, levels = c("noRhizobia", "Rhizobia")) 
data$Temperature <- factor(data$Temperature, levels = c("RT", "26", "30"))  # RT = room temp

# Plot 1: Fresh shoot weight vs Temperature (faceted by genotype, color by rhizobia presence):contentReference[oaicite:7]{index=7}
ggplot(data, aes(x = Temperature, y = Fresh_weight_shoot, color = Microbe, group = Microbe)) +
  stat_summary(fun = mean, geom = "line") + 
  stat_summary(fun = mean, geom = "point") +
  facet_wrap(~ Genotype) +
  labs(title = "Fresh Shoot Weight vs Temperature", 
       x = "Temperature (°C)", y = "Fresh Shoot Weight (g)", color = "Inoculation")

# Plot 2: Total root length vs Temperature (WT vs symrk, with/without rhizobia)
ggplot(data, aes(x = Temperature, y = Root_length, color = Microbe, group = Microbe)) +
  stat_summary(fun = mean, geom = "line") + 
  stat_summary(fun = mean, geom = "point") +
  facet_wrap(~ Genotype) +
  labs(title = "Root Length vs Temperature", 
       x = "Temperature (°C)", y = "Total Root Length (cm)", color = "Inoculation")

# Plot 3: Root volume vs Temperature (WT vs symrk, with/without rhizobia)
ggplot(data, aes(x = Temperature, y = Root_volume, color = Microbe, group = Microbe)) +
  stat_summary(fun = mean, geom = "line") + 
  stat_summary(fun = mean, geom = "point") +
  facet_wrap(~ Genotype) +
  labs(title = "Root Volume vs Temperature", 
       x = "Temperature (°C)", y = "Root Volume (cm^3)", color = "Inoculation")
