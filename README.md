# Colonial India Legislative Dataset Project
 
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Colonial India Legislative Dataset Project](#colonial-india-legislative-dataset-project)
- [Project Description](#project-description)
- [Data Collection](#data-collection)
  - [Collecting Legislative Debates and Votes](#collecting-legislative-debates-and-votes)
  - [Collecting Member Level Data](#collecting-member-level-data)
  - [Collecting Election Level Data](#collecting-election-level-data)
  - [Collecting District Level Data (Including Electoral Rules)](#collecting-district-level-data-including-electoral-rules)
- [Allocation of Tasks](#allocation-of-tasks)

<!-- markdown-toc end -->

## Project Description
In this project, we are attempting to compile a comprehensive dataset of legislative activity in British India between 1919, when bicameral legislative parliament was instituted and limited suffrage was granted, and the period directly following Indian independence, which was declared in 1947.
During this period, the Indian government transitioned from having no elected members of parliament pre-1919 to having all members elected post 1947.
Specifically, we are interested in compiling data about:

1. the text of legislative debates;
2. the voting record of legislators;
3. information about the legislators, including party membership; 
4. the policies/laws promulgated by the parliament;
5. the results of elections during this period, by district and candidate;
6. the electoral rules for each district; and
7. the legislative rules for each legislative chamber.

The goal is to have the information in each of the above points summarized in discrete data tables, but with an identification procedure that allows us to connect information across the datasets as needed.
Using this dataset, we hope to be able to answer research questions like:

- Were certain types of policies discussed more frequently than others after suffrage expansion?
  If so, did legislators who were elected more likely to advocate for certain issues than legislators who were appointed? 
  Did this relationship become more pronounced as time went on?
- Were MP's from more competitive districts more likely to advocate the expansion of education policy?
- Were politicians who were previously appointed more or less likely to successfully fend of a challenger once faced with an election?
- How did the rules of conduct that were inherited by the Indian Legislature from the British House of Commons change as independence was granted? Which rules stayed the same, and which changed? 

## Data Collection
### Collecting Legislative Debates and Votes
Using historic documents between 1919 and 1947, we are compiling a dataset where every row is an individual speech made by a legislator.
So far, we have used a process called Optical Character Recognition (OCR) to turn scanned pages of legislative debates into raw text.
This raw text is then split up into individual speeches using text recognition algorithms.
The goal is to end up with a dataset of the form:

| speech_id | mp_id | speech_date | chamber | speech_text    |
|:----------|:------|:------------|:--------|:---------------|
| 1235      | 459   | 01/01/1920  | cald    | blah blah blah |

While a lot of this can be done via automation, there will need to be a certain amount of auditing to ensure that the algorithms are doing their work correctly.
In addition, the algorithm sometimes corrupts the names of the legislators, and if we want to be able to reliable link each speech to a legislator, it will be necessary to go through the names and make sure that they are consistent.

Using the same historic documents, we also want to compile the votes of each of the MP's. 
We're going to use a similar process as described above to extract the text summarizing MP voting, with the goal of ending up with a dataset of the form:

| proposal_id | vote_id | vote_type | mp_id | vote_date  | chamber | vote_result |
|:------------|:--------|:----------|:------|:-----------|:--------|:------------|
| 1352346     | 8972834 | bill      | 459   | 01/01/1920 | cald    | yes         |

### Collecting Member Level Data
We also want a discrete dataset of member level data, of the form:

| mp_id | elec_id | dist_id | party | ethnicity |
|:------|:--------|:--------|:------|:----------|
| 459   | 90724   | 389     | inc   | hindu     |
| 459   | 90725   | 389     | inc   | hindu     |

where other variables of interested can also be added as additional columns.
The idea is to be able to link up biographical information from each MP to the speeches they made as well as which election(s) they took part in and for which district.

### Collecting Election Level Data 
Similarly, we want a dataset that contains information about each election, including who ran, what district they ran in, how many votes they received, whether they won, etc.
This would look like:

| elec_id | dist_id | elect_date | elec_rules       | runner_id | mp_id | num_votes | result |
|:--------|:--------|:-----------|:-----------------|:----------|:------|:----------|--------|
| 90724   | 389     | 01/10/1919 | landholders only | 12315     | 459   | 10123     | win    |
| 90724   | 389     | 01/10/1919 | landholders only | 12123     | NA    | 4123      | lose   |

### Collecting District Level Data (Including Electoral Rules)
Finally, we would want district level data, including demographic information about population, ethnic makeup, wealth, etc. for each district in a given year. 
We would also want to include what type of electoral rules are used in each district in this dataset.

### Collecting Legislative Rules Data
Coming soon...

## Allocation of Tasks
The initial tasks to get everyone up and running will be to fill out our Member level dataset, as described by Thiha.
However, after this, we can have a conversation about which of the tasks you find most interesting of those described above.
We'll continue to update this document to include resources you can use for each of the tasks.
