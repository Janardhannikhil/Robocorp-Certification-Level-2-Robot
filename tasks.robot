*** Settings ***
Documentation       To order Robots from the Robotsparebinindustries.
...                 saves the order HTML receipt as a PDF file.
...                 saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates the ZIP archive of the receipts and the images.

Library             RPA.Robocorp.Vault
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Archive


*** Tasks ***
To order Robots from the Robotsparebinindustries
    ${asset1}=    Get Secret    robotorderpage
    ${asset2}=    Get Secret    robotordersfile
    open the order-robot page    ${asset1}[orderpage_url]
    ${orders}=    Get orders    ${asset2}[orders_url]
    FOR    ${order}    IN    @{orders}
        close the popup modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds    30s    1s    preview the robot
        Wait Until Keyword Succeeds    30s    1s    submit the order
        ${pdf}=    Store the receipt as PDF file    ${order}[Order number]
        ${screenshot}=    Take the screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    close the browser


*** Keywords ***
open the order-robot page
    [Arguments]    ${orderpage_url}
    Open Available Browser    ${orderpage_url}    maximized=True

Get orders
    [Arguments]    ${orders_url}
    Download    ${orders_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

close the popup modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //input[@type="number"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:preview    2s

submit the order
    Click Element    id:order
    Wait Until Element Is Visible    id:order-completion    2s

Store the receipt as PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_submitted_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}orders${/}order_${order_number}.pdf
    Html To Pdf    ${order_submitted_html}    ${pdf_path}
    RETURN    ${pdf_path}

Take the screenshot of the robot
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    id:robot-preview-image
    ${screenshot-path}=    Set Variable    ${OUTPUT_DIR}${/}previews${/}robot_preview_${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot-path}
    RETURN    ${screenshot-path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_path}    ${pdf_path}
    Open Pdf    ${pdf_path}
    ${files}=    Create List    ${screenshot_path}
    Add Files To Pdf    ${files}    ${pdf_path}    append=True
    Close Pdf

Go to order another robot
    Click Element    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}orders
    ...    ${OUTPUT_DIR}${/}orders.Zip
    ...    recursive=False
    ...    include=order*.pdf

close the browser
    Add heading    close the browser?
    Add submit buttons    yes,no
    ${result}=    Run dialog
    IF    $result.submit == "yes"    Close Browser
