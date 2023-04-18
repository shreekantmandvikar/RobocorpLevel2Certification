*** Settings ***
Documentation   Level 2 Certification
Library         RPA.Browser.Selenium
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
#Library         RPA.Robocorp.Vault
Library         RPA.core.notebook

*** Variables ***
${file_url}=    https://robotsparebinindustries.com/orders.csv  
${site_url}=    https://robotsparebinindustries.com/#/robot-order

# Bot to perfrom below action  :
# 1. Open the website
# 2. Use the csv file and use its each row to create the robot details in website
# 3. After dataentry operations, save the reciept in pdf file format 
# 4. Take the screenshot of Robot and add the robot to given pdf file.
# 5. Finally zip all receipts and save in output directory
# 6. Close the website
*** Tasks ***
Order Processing Bot 
    Intializing steps
    Download the csv file
    ${data}=  Read the order file
    Open the website
    Processing the orders  ${data}
    Zip the reciepts folder
    [Teardown]  Close Browser


***Keywords***
Open the website
    Open Available Browser    ${site_url}
    Maximize Browser Window


***Keywords***
Remove and add empty directory
    [Arguments]  ${folder}
    Remove Directory  ${folder}  True
    Create Directory  ${folder}

***Keywords***
Intializing steps   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}reciepts
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}robots
    Run Keyword If  '${reciept_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}reciepts  ELSE  Create Directory  ${CURDIR}${/}reciepts
    Run Keyword If  '${robots_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}robots  ELSE  Create Directory  ${CURDIR}${/}robots

***Keywords***
Read the order file
    ${data}=  Read Table From Csv  orders.csv  header=True
    Return From Keyword  ${data}

***Keywords***
Data Entry for each order
    [Arguments]  ${row}
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    Click Element  //input[@value="${row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  5 seconds
    Click Button  //button[@id="order"]
    Sleep  5 seconds


***Keywords***
Close and start Browser prior to another transaction
    Close Browser
    Open the website
    Continue For Loop

*** Keywords ***
Checking Receipt data processed or not 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 

***Keywords***
Processing Receipts in final
    [Arguments]  ${row} 
    Sleep  5 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${row}[Order number].png 
    Add Watermark Image To Pdf  ${CURDIR}${/}robots${/}${row}[Order number].png  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf 
    Click Button  //button[@id="order-another"]

***Keywords***
Processing the orders
    [Arguments]  ${data}
    FOR  ${row}  IN  @{data}    
        Data Entry for each order  ${row}
        Checking Receipt data processed or not 
        Processing Receipts in final  ${row}      
    END  


***Keywords***
Download the csv file
    Download  ${file_url}  orders.csv
    Sleep  2 seconds

***Keywords***
Zip the reciepts folder
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}reciepts.zip
