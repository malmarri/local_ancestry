#R code to Plot local ancestry along a single chromosome using the previously generated bed file. 3 samples are plotted together in this script

# Load required libraries
library(ggplot2)
library(dplyr)

# Load the BED files for the three samples
sample1_bed_file <- "SAMPLE1.bed"  # Replace with your first BED file path
sample2_bed_file <- "SAMPLE2.bed"  # Replace with your second BED file path
sample3_bed_file <- "SAMPLE3.bed"  # Replace with your third BED file path

# Function to load and prepare data from a BED file
prepare_bed_data <- function(bed_file, sample_label) {
  bed_data <- read.table(bed_file, header=FALSE, sep="\t", stringsAsFactors = FALSE)
  colnames(bed_data) <- c("chrom", "start", "end", "ancestry")
  bed_data <- bed_data %>%
    mutate(haplotype1 = sapply(strsplit(ancestry, ":"), `[`, 1),
           haplotype2 = sapply(strsplit(ancestry, ":"), `[`, 2)) %>%
    mutate(sample = sample_label,
           start_mb = start / 1e6,  # Convert start position to Mb
           end_mb = end / 1e6)  # Convert end position to Mb
  
  bed_data_hap1 <- bed_data %>%
    select(chrom, start_mb, end_mb, haplotype = haplotype1, sample) %>%
    mutate(row = paste(sample_label, "Haplotype 1", sep = " - "))
  
  bed_data_hap2 <- bed_data %>%
    select(chrom, start_mb, end_mb, haplotype = haplotype2, sample) %>%
    mutate(row = paste(sample_label, "Haplotype 2", sep = " - "))
  
  rbind(bed_data_hap1, bed_data_hap2)
}

# Prepare data for all three samples
bed_data_sample1 <- prepare_bed_data(sample1_bed_file, "Sample 1")
bed_data_sample2 <- prepare_bed_data(sample2_bed_file, "Sample 2")
bed_data_sample3 <- prepare_bed_data(sample3_bed_file, "Sample 3")

# Combine data for all samples
bed_data_stacked <- rbind(bed_data_sample1, bed_data_sample2, bed_data_sample3)

# Ensure no NA values
bed_data_stacked <- bed_data_stacked %>%
  filter(!is.na(haplotype))

# Define the ancestry mapping with descriptive labels
ancestry_colors <- c(
  "AFRICA" = "blue",      
  "AMERICA" = "green",    
  "EAST_ASIA" = "red",    
  "OCEANIA" = "purple",   
  "CENTRAL_SOUTH_ASIA" = "orange",   
  "EUROPE" = "brown",     
  "MIDDLE_EAST" = "yellow"     
)

# Map the numeric ancestry values to their respective labels
bed_data_stacked$haplotype <- factor(bed_data_stacked$haplotype, 
                                     levels = c("0", "1", "2", "3", "4", "5", "6"),
                                     labels = c("AFRICA", "AMERICA", "EAST_ASIA", "OCEANIA", "CENTRAL_SOUTH_ASIA", "EUROPE", "MIDDLE_EAST"))

# Convert the row variable to a factor
bed_data_stacked$row <- factor(bed_data_stacked$row, levels = unique(bed_data_stacked$row))

# Position of the SNP to highlight (convert to Mb)
snp_position_mb <- 75904505 / 1e6  # Convert to Mb

# Create the plot with a vertical line to highlight the SNP and a smaller legend at the bottom
p <- ggplot(bed_data_stacked, aes(xmin=start_mb, xmax=end_mb, ymin=as.numeric(row) - 0.4, ymax=as.numeric(row) + 0.4, fill=haplotype)) +
  geom_rect() +
  geom_vline(xintercept = snp_position_mb, color = "black", linetype = "dashed", size = 1) +  # Add the vertical line
  scale_fill_manual(values = ancestry_colors) +
  scale_y_continuous(breaks=1:length(unique(bed_data_stacked$row)), labels=levels(bed_data_stacked$row)) +
  scale_x_continuous(name="Position on Chromosome (Mb)") +  # Use Mb on the x-axis
  theme_minimal() +
  labs(title="Local Ancestry Plot for Three Samples", y="Haplotype") +
  theme(
    axis.text.y=element_text(size=8),
    axis.ticks.y=element_blank(),
    panel.grid=element_blank(),
    plot.title=element_text(hjust=0.5, size=16),
    legend.title=element_blank(),
    legend.position = "bottom",             # Position the legend at the bottom
    legend.text = element_text(size=8),     # Make the legend text smaller
    legend.key.size = unit(0.5, "cm")       # Make the legend keys smaller
  )

# Save the plot
ggsave("local_ancestry_plot_three_samples_stacked_mb.png", p, width = 15, height = 6, dpi = 300)

# Print the plot
print(p)
