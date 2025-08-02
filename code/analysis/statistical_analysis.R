#####Innobiodiv Script
#Lina and Ana on 20.06.2023

###R version----
#Make sure that your R version is updated every once in a while. There is a really useful package 'installr'.
#It installs the newest version on your computer. while also transferring all your packages to the new R version.
#This should be done in the R terminal not in R studio, because this might lead to problems later.
#R studio will automatically work with the newest version of R. if you want to check your R version, you see it in the console.

#updating R

#restartR if necessary
.rs.restartR()   



### Working environment----
#Before working in R make sure that you do not have any objects in your working environment from previous R sessions.

ls()#To see remaining objects in your working environment
rm(x) #clear specific object (x) from your environment

#You should also make sure that you are in the right working directory either by using projects or setting it be setwd()
#setwd() set the working directory for the current R session
#So that you can load files by just using their file name without using the whole file path



# Load packages----
#For working in R, you need specialized packages.These are all the package and their purpose, we are going to use.
install.packages("ggpubr")
install.packages("dplyr") #it offers a more intuitive and efficient way to work with data frames and performs common data manipulation tasks such as filtering rows, selecting columns, summarizing data, joining tables, and more.
install.packages("ggplot2") #it is based on the grammar of graphics, which allows you to build complex and customized visualizations by combining different components.
install.packages("RColorBrewer") #provides a collection of color palettes for data visualization
install.packages("tidyverse") #collection of several packages designed to work together and provide a cohesive data manipulation and visualization workflow
install.packages("broom") #provides functions to convert the output of various statistical models into tidy data frames. The goal of "broom" is to take messy model output and transform it into a structured format that is easier to work with for further analysis, visualization, or reporting.
install.packages("agricolae") #it offers tools for conducting experiments, performing statistical analyses, and generating agronomic statistics.
install.packages("dplyr") #it offers a set of intuitive and efficient functions for transforming, summarizing, filtering, and joining datasets in R
install.packages("purrr") #provides a consistent and intuitive approach to iterating over data structures and applying functions to elements within those structures
install.packages("tidyr") #where each column represents a variable, each row represents an observation, and each cell contains a single value.
install.packages("Hmisc") #descriptive statistics, data handling, regression modeling, and reporting.
install.packages("ade4") #the package stands for "Analysis of Ecological Data: Exploratory and Euclidean Methods in Environmental Sciences" and is widely used in the field of ecology.
install.packages("ggrepel") #it allows you to prevent overlapping text labels in your plots, making them more readable and aesthetically pleasing.
install.packages("ggsignif") #add annotations based on statistical tests and p-values.
install.packages("readxl") #popular package for importing Excel data into R for further analysis.
install.packages("FSA") #provides a wide range of functionality, including data visualization, statistical modeling, population dynamics analysis, stock assessment, and more
install.packages("rcompanion") #it offers various functions to assist with data exploration, hypothesis testing, effect size estimation, correlation analysis, and more.
install.packages("rstatix") #it aims to simplify common statistical procedures and hypothesis testing tasks in R.
install.packages("ggsignif")
install.packages("stats")

#use the code "if require" if you are not sure if the package is already installed 
if(!require(dplyr)) install.packages("dplyr")


rm(list=ls())#Clear your whole workspace

#load packages into your current R session. Loading a package makes its functions, datasets, and other resources available for use in your R code.
library(ggpubr)  #kruskal test
library(ggplot2) #visualize data
library(RColorBrewer)#color packages
library(tidyverse)#data manipulation
library(broom)#data manipulation
library(agricolae)#statistics
library(dplyr)#data managment
library(purrr)#data managment
library(tidyr)#data managment
library(Hmisc)#data managment
library(ade4)#statistics
library(ggrepel)#add text to a plot
library(ggsignif)#add p values + statistics on a plot
library(readxl)#read excel files
library(FSA)
library(rcompanion)
library(rstatix)   
library(ggsignif)


#loading data----

#There are several ways to load data in your R working environment:
#you can load excel files via read_excel, csv files via read_csv,tsv files via read_tsv, any delimited files with read_delim


dataset <- read_excel("Experiment_results.xlsx",sheet = "Group1")

View(dataset)#shows the full data frame
head(dataset)#gives you the names of the columns
nrow(dataset)#number of rows in your data
ncol(dataset)#number of columns in your data
dim(dataset)#number of columns and rows

#R syntax---
#There are three variations or R Syntax:
#1. Dollar sign syntax- used by most base functions of R, by using $ you refer to variables in a dataset (dataset$variables)
#2. Formula syntax- used by modeling functions like lm() or aov(), using ~ to connect variables
#3. Tidyverse syntax- used by dplyr and tidyr, uses the pipe operator (%>%) to refer to the data, which is expected to be the first argument in the function. ggplot2 uses + to connect the different functions 

#Tidying up our data----
#dplyr functions work with pipes and expect tidy data. In tidy data: each variables is in its own column and each observation or case is in its row
#We are going to use pipe operator  (%>%) to refer to our data. The shortcut is ctrl+shift+m for %>%.

#Since most of the function do not like Nas (missing values), we will exclude them from our data by using drop_na(). This removes all Nas from one specific column/variable.
dataset %>% 
  drop_na(Leaves_number)->dataset2


#For some of the work, we are going to do, we need tidy data. So we gonna clean our data and have one observation in one row.
#make sure your vectors in the data set all have the right type. Otherwise, you might run into some problems.
dataset2$`Fresh_weight_shoot`<-as.numeric(dataset2$`Fresh_weight_shoot`) #it was set as a character, this interfered with our data cleaning, so we are setting as numeric
dataset2$`Fresh_weight_root`<-as.numeric(dataset2$`Fresh_weight_root`)
dataset2$`Shoot_height`<-as.numeric(dataset2$`Shoot_height`)
dataset2$`Shoot_root_ratio`<-as.numeric(dataset2$`Shoot_root_ratio`)
dataset2$`Leaves_number`<-as.numeric(dataset2$`Leaves_number`)
dataset2$`Nodules_number`<-as.numeric(dataset2$`Nodules_number`)

#For tidy data one observation per row is needed. Therefore, we are going to collapse our measured variables into one column and the values into another column by using pivot_longer() from dplyr
dataset2 %>% 
  pivot_longer(c(Fresh_weight_shoot,Fresh_weight_root,Shoot_height, Shoot_root_ratio, Leaves_number, Nodules_number),names_to="Measurement", values_to="values" )-> dataset3

#Types
#There are four types of vectors:
#1. Logical (True,False)
#2. Numeric (1,2,3)
#3. character (blue, red)
#4. Factor (blue, red)-character vectors with preset levels (blue and red)for statistic models

#You can convert from a higher value in the table to a lower values by using as.numeric, as.character, as.factor

#for the statistical analysis, you need factors with levels to use some functions

#converting to factors
dataset3$Measurement<-as.factor(dataset3$Measurement)


#converting to factors and ordering our levels
dataset2$Microbe= factor(dataset2$Microbe)
dataset2$Genotype = factor(dataset2$Genotype, levels=c("WT", "symrk"))
dataset2$Temperature = factor(dataset2$Temperature, levels=c("RT", "26", "30"))

#for statistical analysis we are going to generate a new variable, which is a combination of our three variables
dataset2$Condition<-paste(dataset2$Genotype,dataset2$Microbe,dataset2$Temperature, sep="_")
dataset2$Condition<-as.factor(dataset2$Condition)

####Statistics----
#descr. stat----
#Before we visulalizing our data, we are going to check descriptive statistics (mean, standard_deviation and number of replicates) for our data
#We are going to use our tidy data from the previous section
dataset3 %>%
  arrange(Microbe, Genotype, Temperature, Measurement) %>% #arrange your data according to your variables of desire
  na.omit() %>% #get rid of remaining NAs 
  group_by(Microbe, Genotype, Temperature, Measurement) %>% #grouping your data according to variables for the next functions
  summarise(Average = mean(values), #calculates the mean of your groups
            standard_deviation= sd(values),#calculates the sd of your groups
            number_of_replicates = n()) -> desc_stats_data #calculates the number of replicates and generates a new data frame

#make sure that everything in your new data frame is correct before saving it to a file
#You can save your data by using write_csv, write_delim, write_excel_csv or write_file.

write.table(desc_stats_data, "desc_stats_group1.txt", sep = "\t", row.names = F)

#Statistics for significance----

#Before we do any statistics, we are going to test the distribution of our data.
#There are four types of data distribution: normal, poisson, binomial and uniform. These influence, which test you should choose for your data.
#checking our data distribution
hist(dataset2$Leaves_number)#to visualize data distribution
shapiro.test(dataset2$Leaves_number)#Compute Shapiro-Wilk test of normality
#the shapiro test is not significant (p>0.05). Therefore, we can assume normal distribution of the data.

#Since we have normal distributed data, we can do an anova for our three variables
#Since we don't have normal distributed data, we can do a Kruskal test for our three variables
kruskal.test(Leaves_number~Microbe, data = dataset2) -> kruskal.result
p_value <- round(kruskal.result$p.value, 3)

#saving our results
#notnow write.table(model_phen, "farmbot3_anova.txt", sep = "\t", row.names = F)

###Visualization----

#Plot setting----

#Before we are plotting our data, we are going to set some parameters, which we will use often.

#Position
#To exclude overplotting or data overlapping, we are going to set some position settings
posn_d <- position_dodge(0.9)#values could be between 0 (no separation between columns) and 1 (wide separation between the columns)
posn_j<-position_jitter(0.3)#adds jittter to your data points in geom_point


#Colours
#Sometimes it is useful to set specific colors for your variables. We will do this for our genotypes
myColours<-c('WT'= "#c3cf0a",'symrk' ="#700acf")

#Visualization of our data----

#Plot----
#getting the groups for our significance to add on the plot
#Get highest quantile for Tukey's 5 number summary and add a bit of space to buffer between upper quantile and label placement
abs_max<-max(dataset2$Leaves_number)
maxs<-dataset2 %>% 
  group_by(Genotype, Microbe, Temperature, Condition) %>% 
  summarise(Leaves_number=max(Leaves_number)+0.1*abs_max)



#using ggplot to plot our data
ggplot(dataset2, aes(Temperature, Leaves_number, facet.by = "Microbe", short.panel.labs = FALSE))+
  geom_boxplot(position=posn_d,aes(col=Genotype))+
  stat_summary(fun.data = mean_sdl,
               fun.args = list(mult=1),
               position = posn_d, aes(col=Genotype))+#define your geom
  geom_jitter(position = posn_d, aes(col = Genotype), size = 1.3) +
  #stat_compare_means(method = "kruskal.test", label.y = 2.3)+
  scale_colour_manual(values=myColours)+#setting the colours
  stat_compare_means(ref.group = "RT", method = "wilcox.test",label="p.signif", label.y = 25, hide.ns = FALSE)+
  facet_wrap(.~Microbe)+#dividing the plot in factes according to variable
  labs(y= "Leaves number", x = "Temperature")+#rename your y and x axis labels
  theme_classic()+
  theme(rect = element_blank(), text = element_text(size=16, face = "bold", color = "black"),
        legend.title = element_blank(), axis.text.x =element_text(color = "black", size = 10), axis.text.y = element_text(hjust=1),
        panel.spacing.x =(unit(1,"lines")), strip.background = element_rect(color="grey") )+#defining your theme
  annotate("text", x = 1.3, y = 23, hjust = 1, vjust = 1, label = paste0("p =", p_value), color = "black") +
  NULL

