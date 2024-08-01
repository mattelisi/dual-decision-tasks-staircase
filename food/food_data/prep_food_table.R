rm(list=ls())
hablar::set_wd_to_script_path()

library(tidyverse)
library(readxl)

d <- read_excel("F4H_Collection_n377_food pictures_nutrient_info_vdec18.xlsx", sheet="FoodImage_data")
str(d)
d1 <- data.frame(
  Number = d$ImageNr,
  Name = d$Description,
  Energy_per_100g = d$`Energy (kcal/100g)`,
  Total_energy_on_plate = NA
)


# In the nutritional knowledge task (i.e., Trivia - Foods),
# participants were shown two images of 100g food servings (e.g., jelly beans or sausages) and asked
# to identify the plate with the most calories. 

library(pdftools)
text <- pdf_text("1-s2.0-S0195666315300088-mmc3.pdf")
lines <- strsplit(text, "\n")[[1]]
data_lines <- lines[-1]

# Function to clean and split lines into columns
process_line <- function(line) {
  # Remove extra spaces and split by multiple spaces
  parts <- unlist(strsplit(gsub("\\s+", " ", trimws(line)), " "))
  # Handle cases where Name might contain multiple words
  if (length(parts) > 4) {
    name <- paste(parts[2:(length(parts)-2)], collapse = " ")
    parts <- c(parts[1], name, parts[(length(parts)-1):length(parts)])
  }
  return(parts)
}

# Apply the function to all data lines
data_list <- lapply(data_lines, process_line)

# Convert the list to a data frame
df <- do.call(rbind, data_list) %>% as.data.frame(stringsAsFactors = FALSE)

# Set the column names
colnames(df) <- c("Number", "Name", "Energy_per_100g", "Total_energy_on_plate")

# Convert numeric columns to numeric types
df$Energy_per_100g <- as.numeric(gsub(",", ".", df$Energy_per_100g))
df$Total_energy_on_plate <- as.numeric(gsub(",", ".", df$Total_energy_on_plate))

df

(nrow(df) * (nrow(df)-1)) /2 # 1891 pairs

# check log-ratio of calories on plate
calories_pairs <- rep(NA, (nrow(df) * (nrow(df)-1)) /2)
counter <- 0
for(i in 1:nrow(df)){
  for(j in (i+1):nrow(df)){
    counter <- counter + 1
    calories_pairs[counter] <- (df$Total_energy_on_plate[i]/df$Total_energy_on_plate[j])
    # calories_pairs[counter] <- (df$Energy_per_100g [i]/df$Energy_per_100g [j])
  }
}


str(d1)
str(df)
d1$image <- str_c(d1$Number,".jpg")
df$image <- str_c(df$Number,".jpg")

write_csv(d1, file="all_food.csv")
write_csv(df, file="all_onplate_food.csv")
