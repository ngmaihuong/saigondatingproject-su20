#Saigon Dating Project
#Mai-Huong, Nguyen
#Date created: 07/01/2020
#Date last updated: 08/21/2020

#Opening Tools ----
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(forcats)
library(tidyverse)
library(scales)
library(RColorBrewer)
library(inlmisc)
library(munsell)
library(plyr)
library(writexl)

#Setting Working Directory ----
setwd("~/Downloads/SGD/Data Analytics/MKT Analytics/Final Data")

#Importing Data ----
df <- read.csv('19 SURVEY_August 12, 2020_02.29 copy.csv', 
                   header = TRUE,
                   na.strings = "") #Code can be used for file with choice texts as well
df1 <- read.csv('19 SURVEY_August 12, 2020_02.29.csv', 
               header = TRUE,
               na.strings = "")

#Replace Year of Birth and Employment Status columns
df$X3_1 <- df1$X3_1
df$X7 <- df1$X7
rm(df1)

#Deleting first two rows
df <- df[-c(1,2), ]
rownames(df) <- NULL

#Transforming Data Frame ----

#No scientific notation
options(scipen=5)

#Defining functions

completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

#Adjusting time settings (not necessary)
df$StartDate <- ymd_hms(df$StartDate, tz="Asia/Bangkok")
df$EndDate <- ymd_hms(df$EndDate, tz="Asia/Bangkok")
df$RecordedDate <- ymd_hms(df$RecordedDate, tz="Asia/Bangkok")

#Reframing Data Frame
colnames(df) #to identify variables to keep and their names
df <- df %>% select(StartDate, 
#                   EndDate,
                    Duration..in.seconds.,
                    RecordedDate,
                    X1,
                    X3_1:X11_1,
                    X13:X14,        
                    X1.1:X5.1,
                    X9,
                    X11_4:X11_7)

oldnames = colnames(df)
newnames = c("StartDate", 
#             "EndDate", 
             "Duration", 
             "RecordedDate",
             "UserEmail",
             "BirthYear",
             "Gender",
             "PartnerGender",
             "Education",
             "EmploymentStatus",
             "StudyAbroad",
             "StatusImportance",
             "FinanceImportance",
             "Commitment",
             "ChineseZodiac",
             "Religion",
             "P2Q1",
             "P2Q2",
             "P2Q3",
             "P2Q4",
             "P2Q5",
             "Budget",
             "P2Q11a",
             "P2Q11b",
             "P2Q11c",
             "P2Q11d")
df <- df %>% rename_at(vars(oldnames), ~ newnames)
#df <- na.omit(df)

#Removing empty responses
df <- completeFun(df, "BirthYear")

#Conditioning Time Variables
df <- df %>% separate(StartDate, c("StartDate","StartTime"), sep=" ")
#  separate(EndDate, c("EndDate", "EndTime"), sep=" ")
df <- df %>% separate(StartDate, c('empty', 'StartDate'), sep="020-") %>%
#  separate(EndDate, c('empty1', 'EndDate'), sep="020-") %>%
  select(-empty)#, -empty1)

#Recoding Factors
df <- df %>% mutate(Budget = fct_recode(Budget,
                                        "Dưới 50,000 VNĐ" = '1',
                                        "50,000 VNĐ - 100,000 VNĐ" = '2',
                                        "100,000 VNĐ - 150,000 VNĐ" = '3',
                                        "150,000 VNĐ - 200,000 VNĐ" = '4',
                                        "Trên 200,000 VNĐ" = '5'))

df <- df %>% mutate(Education = fct_recode(Education,
                                          "Đang học cấp 3" = '1',
                                          "Đã tốt nghiệp cấp 3" = '2',
                                          "Đang học Đại học" = '3',
                                          "Đã tốt nghiệp Đại học" = '4',
                                          "Đang học Cao học" = '5',
                                          "Đã học xong Cao học" = '6'))

#Modifying Gender Values
df$Age <- 2021 - as.numeric(as.character(df$BirthYear))

rownames(df) <- NULL

#Find the index of the last person on the old 'Gender/Sexuality' question
df[df$UserEmail=='Gjdjdjnnsksks',]

#Break the dataset into 2: Before and after modifying the 'Gender/Sexuality' question
df1 = df[1:172,]
df2 = df[173:422,] #is there a better way to get row index?

df3 <- df1
df3 <- separate(df3, PartnerGender, c("PartnerGender1", "PartnerGender2"), sep=",")

df3_a <- df3[is.na(df3$PartnerGender2), ]
df3$PartnerGender2[is.na(df3$PartnerGender2)] <- df3_a$PartnerGender1

#If the person is attracted to those of the same gender OR they don't care about their partner gender, they are put into LGBTQ+ group (coded 3)
df3_b <- df3[(df3$Gender == df3$PartnerGender1)|(df3$Gender == df3$PartnerGender2)|(df3$PartnerGender1 == 7)|(df3$PartnerGender2 == 7), ]
df3_b$Gender <- 3
df3[c(rownames(df3_b)),] <- df3_b

df3$Gender <- ifelse(df3$Gender == 1, "Nam", 
                     ifelse(df3$Gender == 2, "Nữ", "LGBTQ+"))

#Remove NA's that somehow appeared
df3 <- completeFun(df3, "UserEmail")

df2$Gender <- ifelse(df2$Gender == 1, 'Nam',
                     ifelse(df2$Gender == 2, 'Nữ',
                            ifelse(df2$Gender == 3, 'Nam',
                                   ifelse(df2$Gender == 4, 'Nữ', 'LGBTQ+'))))
df2 <- select(df2, -PartnerGender)
df3 <- select(df3, c(-PartnerGender1, -PartnerGender2))
df3 <- rbind(df3, df2)

#Saving Data Frame ----
write.csv(df, "Data20200811-Ced.csv", row.names = F)
rownames(df) <- NULL

#Visualization ----
brand = c("#d3a0b7", "#dfc9b1", "#4b82a0")
#"#283e59"
#'#ee1b51'

#Response Date and Time ----
by_date <- df %>% 
  group_by(StartDate) %>% 
  dplyr::count(StartDate) %>% 
  arrange(desc(StartDate)) %>% 
  dplyr::rename('ResponseQuantity'=n)

df %>% ggplot(aes(x=StartDate)) + geom_bar(fill=brand[3]) + 
  labs(title="Số lượng khảo sát nhận được theo ngày", x="Ngày (mm-dd)",y="Số lượng") + 
  theme(plot.title = element_text(hjust=0.5, face="bold"), 
        axis.text.x = element_text(angle=45, hjust=1))

#Adjusting time settings
df$StartTime <- hms(df$StartTime)
#df$EndTime <- hms(df$EndTime)

df$StartHour <- lubridate::hour(df$StartTime)
#df$EndTime <- hour(df$EndTime)

df %>% ggplot(aes(x=StartHour)) + geom_bar(fill=brand[3]) +  
  labs(title="Số lượng khảo sát nhận được theo giờ", x="Giờ",y="Số lượng") + 
  theme(plot.title = element_text(hjust=0.5, face="bold"))

# #Before the pinned post (no longer relevant on new data)
# df1 <- df %>% filter(StartDate < "06-30")
# 
# df1 %>% ggplot(aes(x=StartHour)) + geom_bar(fill=brand[3]) +
#   labs(title="Số lượng khảo sát nhận được theo giờ \n(trước khi đăng pinned post)", x="Giờ", y="Số lượng") +
#   theme(plot.title = element_text(hjust=0.5, face="bold"))
# 
# #After the pinned post
# df2 <- df %>% filter(StartDate >= "06-30")
# 
# df2 %>% ggplot(aes(x=StartHour)) + geom_bar(fill=brand[3]) +
#   labs(title="Số lượng khảo sát nhận được theo giờ \n(sau khi đăng pinned post)", x="Giờ", y="Số lượng") +
#   theme(plot.title = element_text(hjust=0.5, face="bold"))

# Response Duration ----
df$Duration <- as.numeric(levels(df$Duration))[df$Duration]
#df$Duration <- df$Duration / 60

#Overview
cor(df$Age, df$Duration) #no linear relationship
boxplot(log(df$Duration)) #outliers spotting

#Finding outliers

Q <- quantile(df$Duration, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(df$Duration)
up <-  Q[2]+1.5*iqr # Upper Range  
low <- Q[1]-1.5*iqr # Lower Range

#Eliminating outliers
df_1 <- subset(df, df$Duration > (Q[1] - 1.5*iqr) & df$Duration < (Q[2]+1.5*iqr))

#Plotting
cor(df_1$Age, df_1$Duration) #after eliminating outliers

df_1 %>%
  ggplot(aes(x=Age, y=Duration)) +
  geom_point(color=brand[3]) + #+ geom_smooth(method=loess, formula = y~x, level=0.99) 
  labs(title="Mối liên hệ giữa độ tuổi và \nthời gian làm khảo sát", x="Độ tuổi", y="Thời gian làm khảo sát (theo giây)") +
  theme(legend.position = "none", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14)) +
  xlim(0, 37)

#Gender Composition ----

# Compute percentages
by_gender <- df3 %>% 
  group_by(Gender) %>% 
  dplyr::count(Gender) %>% 
  arrange(Gender) %>% 
  dplyr::rename('ResponseQuantity'=n)

by_gender$fraction <- by_gender$ResponseQuantity / sum(by_gender$ResponseQuantity)
by_gender$ymax <- cumsum(by_gender$fraction)

# Compute the bottom of each rectangle
by_gender$ymin <- c(0, head(by_gender$ymax, n=-1))

# Compute label position
by_gender$labelPosition <- (by_gender$ymax + by_gender$ymin) / 2

# Compute a good label
by_gender$label <- paste0(by_gender$Gender, "\n value: ", by_gender$ResponseQuantity)

ggplot(by_gender, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=Gender)) +
  geom_rect(colour="White") +
  geom_text(aes(x=2.4, y=labelPosition, label=label), size=3, color=brand, inherit.aes = F) + # x here controls label position (inner / outer)
  scale_fill_manual(values=brand) +
  coord_polar(theta="y") +
  xlim(c(1, 4)) +
  theme_void() + 
  theme(legend.position = "none", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=18)) +
  labs(title="Tỉ lệ giới tính tham gia khảo sát \nN = 422")

#Gender and Other Variables ----
count(df$StudyAbroad)

#Study Abroad
df3 %>% group_by(Gender, StudyAbroad) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=StudyAbroad, y=count, x=Gender)) + 
  geom_bar(position="stack", stat="identity") + 
  scale_fill_manual(values=c(brand[2], brand[1]), 
                    name="Du học sinh?",
                    labels=c("Có", "Không")) +
  labs(title="Phân loại giới tính và trải nghiệm du học", x="Giới tính", y="Số lượng") + 
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14), legend.key=element_blank()) 

#Age
df3 %>% group_by(Gender, Age) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=Gender, y=count, x=Age)) + 
  geom_bar(position="stack", stat="identity") + 
  labs(title="Phân loại giới tính và độ tuổi", x="Độ tuổi", y="Số lượng") + 
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14)) + coord_flip() +
  scale_fill_manual(values=brand, 
                    name="Giới tính")

#Education
df3 %>%  group_by(Gender, Education) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=Gender, y=count, x=Education)) +
  #geom_bar(position='dodge', stat='identity') +
  geom_col(position = position_dodge2(width = 0.9, preserve = "single")) +
  coord_flip() +
  scale_fill_manual(values=brand, 
                    name="Giới tính") +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14)) +
  labs(title="Phân loại trình độ học vấn \ndựa trên giới tính", x='Trình độ học vấn', y='Số lượng')

# df %>% ggplot(aes(x=RecordedDate)) +
#   geom_line(aes(y=Age)) +
#   labs(title="Survey Response Time by Age")

#Budget and Other Variables ----
df0 <- df
df <- completeFun(df, "Budget")

df3_0 <- df3
df3_0 <- completeFun(df3_0, 'Budget')

df %>% group_by(Budget) %>%
  ggplot(aes(fill = Budget, x=Budget)) +
  geom_bar() + 
  scale_fill_brewer(name="Chi phí", palette="PuRd") +
  coord_flip() +
  labs(title="Phân loại chi phí sẵn sàng chi trả \ncho buổi hẹn hò đầu tiên", x="Chi phí", y="Số lượng") +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14))

#Gender

df3_0 %>%  group_by(Gender, Budget) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=Budget, y=count, x=Gender)) +
  geom_bar(position='stack', stat='identity') +
  scale_fill_brewer(name="Chi phí", palette="PuRd") +
  labs(title="Phân loại chi phí sẵn sàng chi trả cho buổi hẹn hò đầu tiên \ndựa trên giới tính", x='Giới tính', y='Số lượng') +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14))

df3_0 %>%  group_by(Gender, Budget) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(y=count, x=Gender)) +
  geom_bar(position='fill', stat='identity', aes(fill=Budget)) + 
  scale_fill_brewer(name="Chi phí", palette="PuRd") +
  scale_y_continuous(labels = scales::percent) +
  labs(title="Phân loại chi phí sẵn sàng chi trả cho buổi hẹn hò đầu tiên \ndựa trên giới tính", x='Giới tính', y='Tỷ lệ phần trăm') +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14)) + coord_flip()

#Study Abroad

# df3_0 %>%  group_by(StudyAbroad, Budget) %>%
#   dplyr::summarise(count=n()) %>%
#   ggplot(aes(fill=StudyAbroad, y=count, x=Budget)) +
#   geom_bar(position='dodge', stat='identity') +
#   scale_fill_manual(values=c(brand[2], brand[1]),
#                     name="Du học sinh?",
#                     labels=c("Có", "Không")) +
#   coord_flip() +
#   theme(plot.title = element_text(hjust=0.5, face='bold', size=14)) +
#   labs(title="Phân loại chi phí sẵn sàng chi trả cho một buổi hẹn hò \ndựa trên trải nghiệm du học", x='Chi phí', y='Số lượng')

df3_0 %>% mutate(StudyAbroad = fct_recode(StudyAbroad,
                                      "Có" = '1',
                                      "Không" = '2')) %>%
    group_by(StudyAbroad, Budget) %>%
    dplyr::summarise(count=n()) %>%
    ggplot(aes(fill=Budget, y=count, x=StudyAbroad)) +
    geom_bar(position='dodge', stat='identity') +
    scale_fill_brewer(name="Chi phí", palette="PuRd") +
    coord_flip() +
    theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14)) +
    labs(title="Phân loại chi phí sẵn sàng chi trả cho buổi hẹn hò đầu tiên \ndựa trên trải nghiệm du học", x='Du học sinh', y='Số lượng')

#Age
df3_0 %>%  group_by(Budget, Age) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=Budget, y=count, x=Age)) +
  scale_fill_brewer(name="Chi phí", palette="PuRd") +
  geom_bar(position='stack', stat='identity') +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14)) +
  labs(title="Phân loại chi phí sẵn sàng chi trả cho một buổi hẹn hò \ndựa trên độ tuổi", x='Độ tuổi', y='Số lượng')

#Education
df3_0 %>%  group_by(Budget, Education) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=Budget, y=count, x=Education)) +
  scale_fill_brewer(name="Chi phí", palette="PuRd") +
  geom_bar(position='stack', stat='identity') +
  coord_flip() +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face='bold', size=14)) +
  labs(title="Phân loại chi phí sẵn sàng chi trả cho buổi hẹn hò đầu tiên \ndựa trên trình độ học vấn", x='Trình độ học vấn', y='Số lượng')

# Importance of Finance and Status ----
df <- df0

df$FinanceImportance <- as.numeric(levels(df$FinanceImportance))[df$FinanceImportance]
df$StatusImportance <- as.numeric(levels(df$StatusImportance))[df$StatusImportance]

#Age
df %>% ggplot(aes(x=Age, y=FinanceImportance)) +
  geom_point(color=brand[3]) +
  labs(title="Mối liên hệ giữa độ tuổi và tầm quan trọng của \nkhả năng tài chính của đối phương", x="Độ tuổi", y="Tầm quan trọng của \nkhả năng tài chính của đối phương") +
  theme(legend.position = "none", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14))

df %>% ggplot(aes(x=Age, y=StatusImportance)) +
  geom_point(color=brand[3]) +
  labs(title="Mối liên hệ giữa độ tuổi và tầm quan trọng của \nnghề nghiệp/học vấn của đối phương", x="Độ tuổi", y="Tầm quan trọng của \nnghề nghiệp/học vấn của đối phương") +
  theme(legend.position = "none", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14))

#Finance v. Status
df %>% ggplot(aes(x=FinanceImportance, y=StatusImportance)) +
  geom_point(color=brand[3]) + geom_smooth(method=lm, formula = y~x) +
  labs(title="Mối liên hệ giữa tầm quan trọng của khả năng tài chính và \ntầm quan trọng của nghề nghiệp/học vấn của đối phương", 
       x="Tầm quan trọng của \nkhả năng tài chính của đối phương", 
       y="Tầm quan trọng của \nnghề nghiệp/học vấn của đối phương") +
  theme(legend.position = "none", plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14))

cor(df$StatusImportance, df$FinanceImportance) #There is a strong positive relationship.

#Commitment ----
df$Commitment <- as.numeric(levels(df$Commitment))[df$Commitment]
df3$Commitment <- as.numeric(levels(df3$Commitment))[df3$Commitment]

df %>% ggplot(aes(x=Commitment, y=Age)) +
  geom_point(color=brand[3])

cor(df$Age, df$Commitment) #no-weak association

gender_mean <- ddply(df3, "Gender", summarise, grp.mean=mean(Commitment))

df3 %>% ggplot(aes(x=Commitment, fill=Gender)) + 
  geom_density(alpha = 0.6, color=NA) +
  geom_vline(data=gender_mean, aes(xintercept=grp.mean), color=brand, linetype="dashed") +
  scale_fill_manual(values=brand, name="Giới tính") +
  labs(title="Độ sẵn sàng nghiêm túc với \nmột mối quan hệ dựa trên giới tính", x="Độ sẵn sàng", y="Mật độ xác suất") +
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14))

#Chinese Zodiac ----
df3 %>% group_by(Age, ChineseZodiac, Gender) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=ChineseZodiac, y=count, x=Age)) + 
  geom_bar(position="stack", stat="identity") +
  facet_grid(~Gender, scales = "free_x", space = "free_x") +
  scale_fill_manual(values=c(brand[1], brand[3]), 
                    name="Tầm quan trọng của \ntuổi và con giáp",
                    labels=c("Có", "Không")) +
  labs(title="Phân loại độ tuổi và \ntầm quan trọng của tuổi và con giáp \ntheo giới tính", x="Độ tuổi", y="Số lượng") + 
  theme(plot.title = element_text(hjust=0.5, vjust=1.5, face="bold", size=14))

df3 %>% mutate(StudyAbroad = fct_recode(StudyAbroad,
                                        "Có" = '1',
                                        "Không" = '2')) %>%
  group_by(ChineseZodiac, StudyAbroad) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(fill=ChineseZodiac, y=count, x=StudyAbroad)) +
  geom_bar(position='dodge', stat='identity') +
  scale_fill_manual(values=c(brand[1], brand[3]), 
                    name="Tầm quan trọng của \ntuổi và con giáp",
                    labels=c("Có", "Không")) +
  #coord_flip() +
  theme(plot.title = element_text(hjust=0.5, face='bold', size=14)) +
  labs(title="Phân loại tầm quan trọng của tuổi và con giáp \ndựa trên trải nghiệm du học", x='Du học sinh', y='Số lượng')

#Activities Preferences ----
df0 <- df

df <- completeFun(df, 'P2Q11a')
df4 <- data.frame(df$P2Q11a, df$P2Q11b, df$P2Q11c,df$P2Q11d)

df4_1 <- df4 %>% group_by(df.P2Q11a) %>% dplyr::summarise(count=n())
df4_2 <- df4 %>% group_by(df.P2Q11b) %>% dplyr::summarise(count=n())
df4_3 <- df4 %>% group_by(df.P2Q11c) %>% dplyr::summarise(count=n())
df4_4 <- df4 %>% group_by(df.P2Q11d) %>% dplyr::summarise(count=n())

df4 <- full_join(df4_1, df4_2, by=c("df.P2Q11a"="df.P2Q11b"))
df4 <- full_join(df4, df4_3, by=c("df.P2Q11a"="df.P2Q11c"))
df4 <- full_join(df4, df4_4, by=c("df.P2Q11a"="df.P2Q11d"))

df4 <- dplyr::rename(df4,
                     "Rank"='df.P2Q11a',
                     'Option1'="count.x",
                     'Option2'="count.y",
                     'Option3'="count.x.x",
                     'Option4'="count.y.y")

df4$row_sum = rowSums(df4[,c(-1)]) #just to check

df5 <- data.frame(df$P2Q11a, df$P2Q11b, df$P2Q11c,df$P2Q11d)

df5 <- df5 %>% 
  dplyr::rename('Option1' = 'df.P2Q11a',
         'Option2' = 'df.P2Q11b',
         'Option3' = 'df.P2Q11c',
         'Option4' = 'df.P2Q11d') %>%
  gather(Option, Rank, Option1:Option4)

df5 %>% group_by(Rank, Option) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(x=Rank, y=count)) +
  geom_bar(stat='identity', position='fill', aes(fill=Option)) +
  scale_fill_manual(values=c(brand, '#283e59'), 
                    name='Hoạt động',
                    labels=c('Có nhiều thời gian tìm hiểu \nđối phương mà mình được match',
                             'Có thời gian và cơ hội để giao lưu, \ngặp gỡ với tất cả mọi người tham dự',
                             'Có cơ hội để chia sẻ và học hỏi từ người khác, \ntừ đó hiểu hơn về bản thân mình',
                             'Có những hoạt động trải nghiệm \nvui vẻ, năng động, đáng nhớ')) +
  scale_y_continuous(labels = scales::percent) +
  labs(title="Thành phần những hoạt động trong một buổi hẹn hò \ntheo thứ tự ưa thích", x="Thứ tự", y="Phần trăm") +
  theme(legend.position = "right", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14))

# Challenges and Concerns ----

#Data Frame Conditioning
df6 <- read.csv('19 SURVEY_August 12, 2020_02.29 copy.csv', 
                header = TRUE,
                na.strings = "")

df6 <- df6[-c(1,2), ]

df6 <- df6 %>% select(X4:X5,
                      X7.1:X8_6_TEXT)

oldnames = colnames(df6)
newnames = c("Gender",
             "PartnerGender",
             "Challenge",
             "Challenge_Other",
             "Concern",
             "Concern_Other")
df6 <- df6 %>% rename_at(vars(oldnames), ~ newnames)

df6 <- completeFun(df6, c("Gender", "Challenge", "Concern"))

#Change to Adjusted Gender Variable
df6$Gender <- df3_0$Gender

#Reframing Data Frame
df6 <- df6 %>% separate(Challenge, c("Challenge1", "Challenge2", "Challenge3", "Challenge4"), sep=c(",")) %>%
  separate(Concern, c("Concern1", "Concern2", "Concern3", "Concern4"), sep=c(","))

df6_1 <- data.frame(df6$Gender, df6$Challenge1)
df6_2 <- data.frame(df6$Gender, df6$Challenge2)
df6_3 <- data.frame(df6$Gender, df6$Challenge3)
df6_4 <- data.frame(df6$Gender, df6$Challenge4)
df6_5 <- data.frame(df6$Gender, df6$Concern1)
df6_6 <- data.frame(df6$Gender, df6$Concern2)
df6_7 <- data.frame(df6$Gender, df6$Concern3)
df6_8 <- data.frame(df6$Gender, df6$Concern4)

df6_1 <- df6_1 %>% 
  dplyr::rename("Challenge"="df6.Challenge1") %>%
  na.omit()
df6_2 <- df6_2 %>% 
  dplyr::rename("Challenge"="df6.Challenge2") %>%
  na.omit()
df6_3 <- df6_3 %>% 
  dplyr::rename("Challenge"="df6.Challenge3") %>%
  na.omit()
df6_4 <- df6_4 %>% 
  dplyr::rename("Challenge"="df6.Challenge4") %>%
  na.omit()
df6_5 <- df6_5 %>% 
  dplyr::rename("Concern"="df6.Concern1") %>%
  na.omit()
df6_6 <- df6_6 %>% 
  dplyr::rename("Concern"="df6.Concern2") %>%
  na.omit()
df6_7 <- df6_7 %>% 
  dplyr::rename("Concern"="df6.Concern3") %>%
  na.omit()
df6_8 <- df6_8 %>% 
  dplyr::rename("Concern"="df6.Concern4") %>%
  na.omit()

df6_challenge <- rbind(df6_1, df6_2, df6_3, df6_4)
#df6_challenge <- df6_challenge[df6_challenge$Challenge != 6,]

df6_concern <- rbind(df6_5, df6_6, df6_7, df6_8)
#df6_concern <- df6_concern[df6_concern$Concern != 6,]

rm(df6_1, df6_2, df6_3, df6_4, df6_5, df6_6, df6_7, df6_8)

#Recoding Factors

df6_challenge <- df6_challenge %>% mutate(Challenge = fct_recode(Challenge,
                                          "Thiếu thời gian và năng lượng để hẹn hò" = '1',
                                          "Chưa hiểu bản thân muốn và cần gì" = '2',
                                          "Khác định hướng, lý tưởng và hệ giá trị" = '3',
                                          "Không tin tưởng và bất an với những người xung quanh" = '4',
                                          "Hấp tấp, vội vã chọn sai người" = '5',
                                          "Khác" = '6'))

df6_concern <- df6_concern %>% mutate(Concern = fct_recode(Concern,
                                          "Không cảm thấy rung động" = '1',
                                          "Không biết nên chia tiền \nnhư thế nào" = '2',
                                          "Đối phương không chủ động \nsắp xếp buổi hẹn hò (địa điểm, lịch trình, v.v...)" = '3',
                                          "Đối phương không biết cách \ndẫn dắt câu chuyện, để mình nói quá nhiều" = '4',
                                          "Đối phương hút thuốc, \nuống rượu bia" = '5',
                                          "Khác" = '6'))

#Graphing

df6_challenge %>% group_by(df6.Gender, Challenge) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(x=df6.Gender, y=count)) +
  geom_bar(stat='identity', position='fill', aes(fill=Challenge)) +
  scale_fill_manual(values=c('#4b82a0', '#6fc0ab', "#b0d5d0", '#ffdee5', '#e2b1cd', '#fee8d8'), name="Khó khăn") +
  scale_y_continuous(labels = scales::percent) +
  labs(title="Tỷ lệ những khó khăn khi tìm kiếm \nđối tượng hẹn hò theo giới tính", x="Giới tính", y="Phần trăm") +
  theme(legend.position = "right", plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14)) +
  theme(legend.key = element_rect(color = NA, fill = NA),
        legend.key.size = unit(0.75, "cm"))

# function to increase vertical spacing between legend keys
# @clauswilke
draw_key_polygon3 <- function(data, params, size) {
  lwd <- min(data$size, min(size) / 4)
  
  grid::rectGrob(
    width = grid::unit(0.6, "npc"),
    height = grid::unit(0.6, "npc"),
    gp = grid::gpar(
      col = data$colour,
      fill = alpha(data$fill, data$alpha),
      lty = data$linetype,
      lwd = lwd * .pt,
      linejoin = "mitre"
    ))
}

# register new key drawing function, 
# the effect is global & persistent throughout the R session
GeomBar$draw_key = draw_key_polygon3

df6_concern %>% group_by(df6.Gender, Concern) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(x=df6.Gender, y=count)) +
  geom_bar(stat='identity', position='fill', aes(fill=Concern)) +
  #scale_fill_manual(values = wes_palette("Royal2", n = 5), name="Bận tâm") +
  #scale_fill_brewer(palette = "Set3", name="Bận tâm") +
  scale_fill_manual(values=c('#4b82a0', '#6fc0ab', "#b0d5d0", '#ffdee5', '#e2b1cd', '#fee8d8'), name="Bận tâm") +
  scale_y_continuous(labels = scales::percent) +
  theme_bw() +
  labs(title="Tỷ lệ những điều khiến cho buổi hẹn hò đầu tiên \ntrở nên không thoải mái theo nhóm đối tượng", x="Nhóm đối tượng", y="Phần trăm") +
  theme(legend.position = "right",
        plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14)) +
  theme(legend.key = element_rect(color = NA, fill = NA),
        legend.key.size = unit(1, "cm"))

df6_concern %>% group_by(df6.Gender, Concern) %>%
  dplyr::summarise(count=n()) %>%
  ggplot(aes(x=df6.Gender, y=count)) +
  geom_bar(stat='identity', position='dodge', aes(fill=Concern)) +
  scale_fill_manual(values=c('#4b82a0', '#6fc0ab', "#b0d5d0", '#ffdee5', '#e2b1cd', '#fee8d8'), name="Bận tâm") +
  labs(title="Những điều khiến cho buổi hẹn hò đầu tiên \ntrở nên không thoải mái theo nhóm đối tượng", x="Nhóm đối tượng", y="Số lượng") +
  theme_bw() +
  theme(legend.position = "right",
        plot.title = element_text(hjust=0.5, vjust=0.1, face="bold", size=14)) +
  theme(legend.key = element_rect(color = NA, fill = NA),
        legend.key.size = unit(1, "cm"))

# Free Answer Insights ----
df6_other_1 <- data.frame(df6$Challenge_Other)
df6_other_1 <- df6_other_1 %>% 
  na.omit() %>%
  dplyr::mutate(ID = row_number()) %>%
  dplyr::rename("Khó khăn" = "df6.Challenge_Other")

df6_other_2 <- data.frame(df6$Concern_Other)
df6_other_2 <- df6_other_2 %>% 
  na.omit() %>% 
  dplyr::mutate(ID = row_number()) %>%
  dplyr::rename("Bận tâm" = "df6.Concern_Other")

df6_other <- full_join(df6_other_1, df6_other_2)
df6_other <- select(df6_other, -ID)

#Saving Data as Excel
write_xlsx(df6_other, "20200811-insights.xlsx")

#end
