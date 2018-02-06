*** Settings ***
Library  Selenium2Library
Library  String
Library  Collections
Library  DateTime
Library  allbiz_service.py

*** Variables ***
${custom_acceleration}=  360
${host}=  https://tenders.all.biz

*** Keywords ***

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=  adapt_procuringEntity  ${role_name}  ${tender_data}
  [Return]  ${tender_data}

Підготувати клієнт для користувача
  [Arguments]  ${username}
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${username}
  Set Window Size  1024  768
  Run Keyword If  '${username}' != 'allbiz_Viewer'  Run Keywords
  ...  Login  ${username}
  ...  AND  Run Keyword And Ignore Error  Wait Until Keyword Succeeds  10 x  1 s  Закрити модалку з новинами

Закрити модалку з новинами
  Wait Until Element Is Enabled   xpath=//button[@data-dismiss="modal"]
  Дочекатися І Клікнути   xpath=//button[@data-dismiss="modal"]
  Wait Until Element Is Not Visible  xpath=//button[@data-dismiss="modal"]

Login
  [Arguments]  ${username}
  Дочекатися І Клікнути  xpath=//a[@href="/login"]
  Wait Until Page Contains Element  id=loginform-username  10
  Input text  id=loginform-username  ${USERS.users['${username}'].login}
  Input text  id=loginform-password  ${USERS.users['${username}'].password}
  Дочекатися І Клікнути  name=login-button

###############################################################################################################
######################################    СТВОРЕННЯ ТЕНДЕРУ    ################################################
###############################################################################################################

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${items}=  Get From Dictionary  ${tender_data.data}  items
  ${amount}=   add_second_sign_after_point   ${tender_data.data.value.amount}
  ${meat}=  Evaluate  ${tender_meat} + ${lot_meat} + ${item_meat}
  Switch Browser  ${username}
  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Дочекатися І Клікнути  xpath=//a[@href="${host}/tenders"]
  Дочекатися І Клікнути  xpath=//a[@href="${host}/tenders/index"]
  Дочекатися І Клікнути  xpath=//a[contains(@href,"/buyer/tender/create")]
  Run Keyword If  "below" in "${tender_data.data.procurementMethodType}"  Заповнити поля для допорогової закупівлі  ${tender_data}
  ...  ELSE IF  "aboveThreshold" in "${tender_data.data.procurementMethodType}"  Заповнити поля для понадпорогів  ${tender_data}
  ...  ELSE IF  "${tender_data.data.procurementMethodType}" == "negotiation"  Заповнити поля для переговорної процедури  ${tender_data}
  ...  ELSE IF  "${tender_data.data.procurementMethodType}" == "reporting"  Wait And Select From List By Value  name=tender_method  limited_reporting
  Run Keyword If  ${number_of_lots} > 0  Wait And Select From List By Value  name=tender_type  2
  ...  ELSE  Wait And Select From List By Value  name=tender_type  1
  Conv And Select From List By Value  name=Tender[value][valueAddedTaxIncluded]  ${tender_data.data.value.valueAddedTaxIncluded}
  Wait And Select From List By Value  name=Tender[value][currency]  ${tender_data.data.value.currency}
  Run Keyword If  ${number_of_lots} == 0  Run Keywords
  ...  ConvToStr And Input Text  name=Tender[value][amount]  ${amount}
  ...  AND  Run Keyword If  "${tender_data.data.procurementMethodType}" not in "reporting negotiation"  Select From List By Value  id=guarantee-exist  0
  Input text  name=Tender[title]  ${tender_data.data.title}
  Input text  name=Tender[description]  ${tender_data.data.description}
  Run Keyword If  "${tender_data.data.procurementMethodType}" == "belowThreshold"  Run Keywords
  ...  Input Date  name=Tender[enquiryPeriod][endDate]  ${tender_data.data.tenderPeriod.startDate}
  ...  AND  Input Date  name=Tender[tenderPeriod][startDate]  ${tender_data.data.tenderPeriod.startDate}
  Run Keyword If   ${number_of_lots} == 0  Додати багато предметів   ${tender_data}
  ...  ELSE  Додати багато лотів  ${tender_data}
  Run Keyword If  ${meat} > 0  Додати нецінові критерії  ${tender_data}
  Run Keyword If  "${tender_data.data.procurementMethodType}" != "aboveThresholdUA"  Дочекатися І Клікнути  xpath=//input[@data-test-id="fast_forward"]
  Log  ${SUITE_NAME}
  Run Keyword If  "${SUITE_NAME}" == "Tests Files.Complaints"  Execute Javascript  $('input[name="accelerator"]').val('${custom_acceleration}')
  Get Element Attribute  xpath=//input[@name="accelerator"]@value
  Select From List By Index  id=contact-point-select  1
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Element Is Visible  xpath=//*[@data-test-id="tenderID"]  20
  ${tender_uaid}=  Get Text  xpath=//*[@data-test-id="tenderID"]
  [Return]  ${tender_uaid}

Заповнити поля для допорогової закупівлі
  [Arguments]  ${tender_data}
  Log  ${tender_data}
  ${is_funders}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${tender_data.data}  funders
  ${minimalStep}=   add_second_sign_after_point   ${tender_data.data.minimalStep.amount}
  Wait And Select From List By Value  name=tender_method  open_${tender_data.data.procurementMethodType}
  Select From List By Value  id=tender-type-select  1
  Run Keyword If  ${number_of_lots} == 0  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${minimalStep}
  Run Keyword If  ${is_funders}  Run Keywords
  ...  Click Element  id=funders-checkbox
  ...  AND  Wait And Select From List By Label  id=tender-funders  ${tender_data.data.funders[0].name}
  Input Date  name=Tender[tenderPeriod][endDate]  ${tender_data.data.tenderPeriod.endDate}
  Select From List By Index  id=contact-point-select  1


Заповнити поля для понадпорогів
  [Arguments]  ${tender_data}
  Log  ${tender_data}
  ${minimalStep}=   add_second_sign_after_point   ${tender_data.data.minimalStep.amount}
  Wait And Select From List By Value  name=tender_method  open_${tender_data.data.procurementMethodType}
  Select From List By Value  id=tender-type-select  2
  Run Keyword If  ${number_of_lots} == 0  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${minimalStep}
  Run Keyword If  "EU" in "${tender_data.data.procurementMethodType}"  Run Keywords
  ...  Input Text   name=Tender[title_en]   ${tender_data.data.title_en}
  ...  AND  Input Text   name=Tender[description_en]   ${tender_data.data.description_en}
  Input Date  name=Tender[tenderPeriod][endDate]  ${tender_data.data.tenderPeriod.endDate}
  Select From List By Index  id=contact-point-select  1


Заповнити поля для переговорної процедури
  [Arguments]  ${tender_data}
  Log  ${tender_data}
  Wait And Select From List By Value  name=tender_method  limited_${tender_data.data.procurementMethodType}
  Input Text  name=Tender[causeDescription]  ${tender_data.data.causeDescription}
  Дочекатися І Клікнути  xpath=//input[@name="Tender[cause]" and @value="${tender_data.data.cause}"]/..
  Input Text  name=Tender[procuringEntity][contactPoint][name]  ${tender_data.data.procuringEntity.contactPoint.name}
  Input Text  name=Tender[procuringEntity][contactPoint][telephone]  ${tender_data.data.procuringEntity.contactPoint.telephone}
  Input Text  name=Tender[procuringEntity][contactPoint][email]  ${tender_data.data.procuringEntity.contactPoint.email}
  Input Text  name=Tender[procuringEntity][contactPoint][url]  ${tender_data.data.procuringEntity.contactPoint.url}

Додати багато лотів
  [Arguments]  ${tender_data}
  ${lots}=  Get From Dictionary  ${tender_data.data}  lots
  ${lots_length}=  Get Length  ${lots}
  :FOR  ${index}  IN RANGE  ${lots_length}
  \  Run Keyword if  ${index} != 0  Дочекатися І Клікнути  xpath=//button[contains(@class, "add_lot")]
  \  allbiz.Створити лот  allbiz_Owner  ${None}  ${lots[${index}]}  ${tender_data}

Створити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot}   ${data}=${EMPTY}
  ${lot}=  Set Variable If  '${tender_uaid}' != '${None}'  ${lot.data}  ${lot}
  ${amount}=  add_second_sign_after_point  ${lot.value.amount}
  ${lot_id}=  Get Element Attribute  xpath=(//input[contains(@name, "Tender[lots]") and contains(@name, "[value][amount]")])[last()]@id
  ${lot_index}=  Convert To Integer  ${lot_id.split("-")[1]}
  ${is_guarantee}=  Run Keyword And Return Status  Element Should Be Visible  xpath=(//*[@id="guarantee-exist"])[${lot_index + 3}]
  Input text   name=Tender[lots][${lot_index}][title]                 ${lot.title}
  Input text   name=Tender[lots][${lot_index}][description]           ${lot.description}
  Run keyword If  ${is_guarantee}  Select From List By Value  xpath=(//*[@id="guarantee-exist"])[${lot_index + 3}]  0
  Input text   name=Tender[lots][${lot_index}][value][amount]         ${amount}
  Run Keyword If  "Negotiation" not in "${SUITE_NAME}"  Input Minimal Step Amount  ${lot.minimalStep.amount}  ${lot_index}
  Run Keyword If   '${mode}' == 'openeu'   Run Keywords
  ...   Input Text   name=Tender[lots][${lot_index}][title_en]   ${lot.title_en}
  ...   AND   Input Text   name=Tender[lots][${lot_index}][description_en]    ${lot.description}
  Додати багато предметів   ${data}

Input Minimal Step Amount
  [Arguments]  ${minimal_step}  ${lot_index}
  ${minimalStep}=  add_second_sign_after_point  ${minimal_step}
  Input text  name=Tender[lots][${lot_index}][minimalStep][amount]  ${minimalStep}

Додати багато предметів
  [Arguments]  ${data}
  Log Many  ${data}
  ${status}  ${items}=  Run Keyword And Ignore Error  Get From Dictionary   ${data.data}   items
  @{items}=  Run Keyword If  "${status}" == "PASS"  Set Variable  ${items}
  ...  ELSE  Create List  ${data}
  Log Many  ${items}
  ${items_length}=  Get Length  ${items}
  :FOR  ${index}  IN RANGE  ${items_length}
  \  Run Keyword if  ${index} != 0  Дочекатися і Клікнути  xpath=(//button[contains(@class, "add_item")])[last()]
  \  Додати предмет   ${items[${index}]}


Додати предмет
  [Arguments]  ${item}
  Log Many  ${item}
  ${item_id}=   Get Element Attribute  xpath=(//input[contains(@name, "Tender[items]") and contains(@name, "[quantity]")])[last()]@id
  ${index}=   Set Variable  ${item_id.split("-")[1]}
  ${dk_status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${item}  additionalClassifications
  ${is_CPV_other}=  Run Keyword And Return Status  Should Be Equal  '${item.classification.id}'  '99999999-9'
  ${is_MOZ}=  Run Keyword And Return Status  Should Be Equal  '${item.additionalClassifications[0].scheme}'  'INN'
  Input text  name=Tender[items][${index}][description]  ${item.description}
  Run Keyword If   '${mode}' == 'openeu'   Input text  name=Tender[items][${index}][description_en]  ${item.description_en}
  Input text  name=Tender[items][${index}][quantity]  ${item.quantity}
  Wait And Select From List By Value  name=Tender[items][${index}][unit][code]  ${item.unit.code}
  Scroll To Element  name=Tender[items][${index}][classification][description]
  Дочекатися І Клікнути  name=Tender[items][${index}][classification][description]
  Wait Until Element Is Visible  id=search
  Input text  id=search_code  ${item.classification.id}
  Wait Until Page Contains  ${item.classification.id}
  Дочекатися І Клікнути  xpath=//span[contains(text(),'${item.classification.id}')]
  Дочекатися І Клікнути  id=btn-ok
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Not Be Visible  xpath=//div[@class="modal-backdrop fade"]
  Run Keyword If  ${dk_status} and ${is_CPV_other} or ${is_MOZ}  Вибрати додатковий класифікатор  ${item}  ${index}  ${is_MOZ}
  Wait Until Element Is Visible  name=Tender[items][${index}][deliveryAddress][countryName]
  Wait And Select From List By Label  name=Tender[items][${index}][deliveryAddress][countryName]  ${item.deliveryAddress.countryName}
  Wait And Select From List By Label  name=Tender[items][${index}][deliveryAddress][region]  ${item.deliveryAddress.region}
  Input text  name=Tender[items][${index}][deliveryAddress][locality]  ${item.deliveryAddress.locality}
  Input text  name=Tender[items][${index}][deliveryAddress][streetAddress]  ${item.deliveryAddress.streetAddress}
  Input text  name=Tender[items][${index}][deliveryAddress][postalCode]  ${item.deliveryAddress.postalCode}
  Input Date  name=Tender[items][${index}][deliveryDate][startDate]  ${item.deliveryDate.endDate}
  Input Date  name=Tender[items][${index}][deliveryDate][endDate]  ${item.deliveryDate.endDate}

Вибрати додатковий класифікатор
  [Arguments]  ${item}  ${index}  ${is_MOZ}
  Run Keyword If  not ${is_MOZ}  Wait And Select From List By Value  name=Tender[items][${index}][additionalClassifications][0][dkType]  ${item.additionalClassifications[0].scheme}_dk${item.additionalClassifications[0].scheme[2:]}
  Дочекатися І Клікнути  name=Tender[items][${index}][additionalClassifications][0][description]
  Wait Element Animation  id=search_code
  Run Keyword If  not ${is_MOZ}  Input text  id=search_code  ${item.additionalClassifications[0].id}
  ...  ELSE  Input text  id=search_code  ${item.additionalClassifications[1].id}
  Wait Until Page Contains  ${item.additionalClassifications[0].id}
  Дочекатися І Клікнути  xpath=//span[contains(text(), '${item.additionalClassifications[0].id}')]
  Дочекатися І Клікнути  id=btn-ok
  Wait Element Animation  id=btn-ok

Додати нецінові критерії
  [Arguments]  ${tender_data}
  ${features}=   Get From Dictionary   ${tender_data.data}   features
  ${features_length}=   Get Length   ${features}
  :FOR   ${index}   IN RANGE   ${features_length}
  \   Run Keyword If  '${features[${index}].featureOf}' != 'tenderer'   Run Keywords
  ...  Дочекатися І Клікнути  xpath=(//div[@class="lot"]/descendant::button[contains(text(), "Додати показник")])[last()]
  ...  AND  Додати показник   ${features[${index}]}  ${tender_data}
  \   Run Keyword If  '${features[${index}].featureOf}' == 'tenderer'   Run Keywords
  ...   Дочекатися І Клікнути   xpath=(//div[@class="features_block"]/descendant::button[contains(text(), "Додати показник")])[last()]
  ...   AND   Додати показник   ${features[${index}]}  ${tender_data}

Додати показник
  [Arguments]   ${feature}  ${tender_data}  ${item_id}=${EMPTY}
  ${feature_index}=  Get Last Feature Index
  ${enum_length}=  Get Length   ${feature.enum}
  ${relatedItem}=  Run Keyword If   "${feature.featureOf}" == "item"  get_related_elem_description   ${tender_data}   ${feature}   ${item_id}
  ...  ELSE IF  "${feature.featureOf}" == "lot"  Set Variable  Поточний лот
  ...  ELSE  Set Variable  Все оголошення
  Input text   xpath=//input[@name="Tender[features][${feature_index}][title]"]  ${feature.title}
  Input text   name=Tender[features][${feature_index}][description]   ${feature.description}
  Run Keyword If   '${mode}' == 'openeu'  Run Keywords
  ...  Input text   xpath=//input[@name="Tender[features][${feature_index}][title_en]"]  ${feature.title_en}
  ...  AND  Input text   name=Tender[features][${feature_index}][description_en]   ${feature.description}
  Дочекатися І Клікнути  xpath=//select[@name="Tender[features][${feature_index}][relatedItem]"]/descendant::option[contains(text(),"${relatedItem}")]
  :FOR   ${index}   IN RANGE   ${enum_length}
  \   Run Keyword if   ${index} != 0   Дочекатися І Клікнути   xpath=//input[@name="Tender[features][${feature_index}][title]"]/ancestor::div[@class="feature"]/descendant::button[contains(@class,"add_feature_enum")]
  \   Додати опцію   ${feature.enum[${index}]}   ${index}   ${feature_index}

Index Should Not Be Zero
  [Arguments]  ${feature_index}
  ${element_id}=  Get Element Attribute  xpath=(//input[@class="feature_title" and not (contains(@name, "__EMPTY_FEATURE__"))])[${feature_index}]@id
  Should Not Be Equal As Integers  ${element_id.split("-")[1]}  0

Get Last Feature Index
  ${features_length}=  Get Matching Xpath Count  (//input[@class="feature_title" and not (contains(@name, "__EMPTY_FEATURE__"))])
  ${features_length}=  Convert To Integer  ${features_length}
  :FOR  ${f_index}  IN RANGE  ${features_length}
  \  ${element_id}=  Get Element Attribute  xpath=(//input[@class="feature_title" and not (contains(@name, "__EMPTY_FEATURE__"))])[${f_index + 1}]@id
  \  ${feature_title_value}=  Get Element Attribute  xpath=(//input[@class="feature_title" and not (contains(@name, "__EMPTY_FEATURE__"))])[${f_index + 1}]@value
  \  Run Keyword If  "${feature_title_value}" == "" and "${element_id.split("-")[1]}" == "0"  Wait Until Keyword Succeeds  10 x  2 s  Index Should Not Be Zero  ${f_index + 1}
  \  Return From Keyword If  "${feature_title_value}" == ""  ${element_id.split("-")[1]}

Додати опцію
  [Arguments]  ${enum}  ${index}  ${feature_index}
  ${enum_value}=   Convert To Integer   ${enum.value * 100}
  Scroll To Element  name=Tender[features][${feature_index}][enum][${index}][title]
  Input Text   name=Tender[features][${feature_index}][enum][${index}][title]   ${enum.title}
  Run Keyword If   '${mode}' == 'openeu'  Input Text   name=Tender[features][${feature_index}][enum][${index}][title_en]   ${enum.title}
  Input Text   name=Tender[features][${feature_index}][enum][${index}][value]   ${enum_value}

Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Switch Browser  ${username}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Scroll To Element  xpath=//*[@data-test-id="tender.documents.upload"]/descendant::input[@type="file"][last()]
  Choose File  xpath=//*[@data-test-id="tender.documents.upload"]/descendant::input[@type="file"][last()]  ${filepath}
  ${last_doc_name}=  Get Element Attribute  xpath=(//input[contains(@name,"Tender[documents]") and not (contains(@name, "__empty_doc__"))])[last()]@name
  ${doc_index}=  Set Variable  ${last_doc_name.split("][")[1]}
  Wait Until Element Is Visible  xpath=//input[@name="Tender[documents][${doc_index}][title]"]
  Input Text  xpath=//input[@name="Tender[documents][${doc_index}][title]"]  ${filepath.split("/")[-1]}
  Select From List By Value  id=document-${doc_index}-relateditem  tender
  Click Button  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу

Дочекатися завантаження документу
  Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Page Does Not Contain  Файл завантажується...  10

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Switch browser  ${username}
  Go To  ${host}/tenders/
  ${is_events_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//button[contains(@id,"-read-all")]
  Run Keyword If  ${is_events_visible}  Click Element  id=buyer-read-all
  Wait Until Element Is Visible  name=TendersSearch[tender_cbd_id]  10
  Input text  name=TendersSearch[tender_cbd_id]  ${tender_uaid}
  Wait Until Keyword Succeeds  6x  20s  Run Keywords
  ...  Дочекатися І Клікнути  xpath=//button[text()='Шукати']
  ...  AND  Wait Until Element Is Visible  xpath=//*[contains(@class, "btn-search_cancel")]  10
  ...  AND  Wait Until Element Is Visible  xpath=//*[contains(text(),'${tender_uaid}')]/ancestor::div[@class="search-result"]/descendant::a[1]  10
  Click Element  xpath=//*[contains(text(),'${tender_uaid}')]/ancestor::div[@class="search-result"]/descendant::a[1]
  Wait Until Element Is Visible  xpath=//*[@data-test-id="tenderID"]  10

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tenderID}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tenderID}

Внести зміни в тендер
  [Arguments]  ${username}  ${tenderID}  ${field_name}  ${field_value}
  ${field_value}=  Run Keyword If  "amount" in "${field_name}"  add_second_sign_after_point  ${field_value}
  ...  ELSE  Set Variable  ${field_value}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tenderID}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Run Keyword If  "Date" in "${field_name}"  Input Date  name=Tender[${field_name.replace(".", "][")}]  ${field_value}
  ...  ELSE  Input text  name=Tender[${field_name}]  ${field_value}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Змінити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${field_name}  ${field_value}
  ${field_value}=  Run Keyword If  "amount" in "${field_name}"  add_second_sign_after_point  ${field_value}
  ...  ELSE  Set Variable  ${field_value}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Input Text  xpath=(//input[contains(@value,"${lot_id}")]/ancestor::div[@class="lots_marker"]/descendant::*[contains(@name,"${field_name.replace(".", "][")}")])[1]  ${field_value}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Завантажити документ в лот
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}  ${lot_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Wait Until Page Contains Element  xpath=//input[contains(@value,"${lot_id}")]/ancestor::div[@class="lots_marker"]/descendant::input[@type="file"][last()]
  Choose File  xpath=//input[contains(@value,"${lot_id}")]/ancestor::div[@class="lots_marker"]/descendant::input[@type="file"][last()]  ${filepath}
  ${last_doc_name}=  Get Element Attribute  xpath=(//input[contains(@name,"Tender[documents]") and not (contains(@name, "__empty_doc__"))])[last()]@name
  ${doc_index}=  Set Variable  ${last_doc_name.split("][")[1]}
  Wait Until Element Is Visible  xpath=//input[@name="Tender[documents][${doc_index}][title]"]
  Input Text  xpath=//input[@name="Tender[documents][${doc_index}][title]"]  ${filepath.split("/")[-1]}
  Select From List By Label  id=document-${doc_index}-relateditem  Поточний лот
  Click Button  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу

Створити лот із предметом закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${lot}  ${item}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Дочекатися І Клікнути  xpath=//button[contains(@class, "add_lot")]
  allbiz.Створити лот  ${username}  ${tender_uaid}  ${lot}  ${item}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати предмет закупівлі в лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${item}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Дочекатися І Клікнути  xpath=//*[contains(@value, "${lot_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class,"add_item")]
  allbiz.Додати предмет  ${item}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати неціновий показник на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${feature}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Дочекатися І Клікнути   xpath=(//div[contains(@class,"features_wrapper")]/descendant::button[contains(@class, "add_feature")])[last()]
  Додати показник   ${feature}  ${EMPTY}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати неціновий показник на лот
  [Arguments]  ${username}  ${tender_uaid}  ${feature}  ${lot_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Sleep  3
  Дочекатися І Клікнути   xpath=(//input[contains(@value,"${lot_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class, "add_feature")])[last()]
  Додати показник   ${feature}  ${EMPTY}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати неціновий показник на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${feature}  ${item_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  ${is_feature_added}=  Run Keyword And Return Status  Should Contain At Least One Feature
  Run Keyword If  ${is_feature_added}  Wait Until Keyword Succeeds  10 x  400 ms  Feature Count Should Not Be Zero
  Дочекатися І Клікнути   xpath=(//textarea[contains(text(),"${item_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class, "add_feature")])[last()]
  Додати показник   ${feature}  ${EMPTY}  ${item_id}
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Should Contain At Least One Feature
  ${feature_count}=  Get Matching Xpath Count  //input[@class="feature_title" and not (contains(@name, "__EMPTY_FEATURE__"))]
  Should Not Be Equal As Integers  ${feature_count}  0

Feature Count Should Not Be Zero
  ${feature_count}=  Execute Javascript  return FeatureCount
  Should Not Be Equal As Integers  ${feature_count}  0

Створити постачальника, додати документацію і підтвердити його
  [Arguments]  ${username}  ${tender_uaid}  ${supplier_data}  ${document}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[text()="Пропозиції"]
  Wait And Select From List By Label  name=Award[suppliers][0][address][countryName]  ${supplier_data.data.suppliers[0].address.countryName}
  Wait And Select From List By Label  name=Award[suppliers][0][identifier][scheme]  Схема ${supplier_data.data.suppliers[0].identifier.scheme}
  Input Text  name=Award[suppliers][0][identifier][id]  ${supplier_data.data.suppliers[0].identifier.id}
  Input Text  name=Award[suppliers][0][name]  ${supplier_data.data.suppliers[0].name}
  Wait And Select From List By Label  name=Award[suppliers][0][address][region]  ${supplier_data.data.suppliers[0].address.region}
  Input Text  name=Award[suppliers][0][address][postalCode]  ${supplier_data.data.suppliers[0].address.postalCode}
  Input Text  name=Award[suppliers][0][address][locality]  ${supplier_data.data.suppliers[0].address.locality}
  Input Text  name=Award[suppliers][0][address][streetAddress]  ${supplier_data.data.suppliers[0].address.streetAddress}
  Input Text  name=Award[suppliers][0][contactPoint][name]  ${supplier_data.data.suppliers[0].contactPoint.name}
  Input Text  name=Award[suppliers][0][contactPoint][telephone]  ${supplier_data.data.suppliers[0].contactPoint.telephone}
  Input Text  name=Award[suppliers][0][contactPoint][email]  ${supplier_data.data.suppliers[0].contactPoint.email}
  Input Text  name=Award[value][amount]  ${supplier_data.data.value.amount}
  Дочекатися І Клікнути  name=add_limited_avards
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]  20
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Дочекатися І Клікнути  xpath=//button[contains(@id,"modal-award-qualification")]
  Choose File  xpath=//*[@class="active"]/descendant::input[@type="file"]  ${document}
  RUn Keyword If  "${MODE}" == "negotiation"  Дочекатися І Клікнути  xpath=(//input[contains(@id,"qualified")])[1]/..
  Дочекатися І Клікнути  name=send_prequalification
  Накласти ЄЦП


###############################################################################################################
###########################################    ВИДАЛЕННЯ    ###################################################
###############################################################################################################

Видалити предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${lot_id}=${Empty}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Дочекатися І Клікнути  xpath=//textarea[contains(text(), "${item_id}")]/ancestor::div[@class="item"]/descendant::button[contains(@class, "delete_item")]
  Confirm Action
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]


Видалити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Sleep  3
  Дочекатися І Клікнути  xpath=//*[contains(@value, "${lot_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class,"delete_lot")]
  Confirm Action
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Видалити неціновий показник
  [Arguments]  ${username}  ${tender_uaid}  ${feature_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//a[contains(text(),'Редагувати')]
  Sleep  3
  Дочекатися І Клікнути  xpath=//*[contains(@value, "${feature_id}")]/ancestor::div[@class="feature"]/descendant::button[contains(@class,"delete_feature")]
  Confirm Action
  Дочекатися І Клікнути  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

###############################################################################################################
############################################    ПИТАННЯ    ####################################################
###############################################################################################################

Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}  ${related_to}=False
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/questions")]
  Input Text  name=Question[title]  ${question.data.title}
  Input Text  name=Question[description]  ${question.data.description}
  ${label}=  Get Text  xpath=//select[@id="question-questionof"]/descendant::option[contains(text(), "${related_to}")]
  Run Keyword If  "${related_to}" != False  Wait And Select From List By Label  name=Question[questionOf]  ${label}
  Дочекатися І Клікнути  name=question_submit
  Wait Until Page Contains  ${question.data.description}

Відповісти на питання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/questions")]
  Toggle Sidebar
  Wait Until Element Is Visible  xpath=(//*[contains(text(), "${question_id}")])[last()]
  Input text  xpath=//*[contains(text(), "${question_id}")]/../descendant::textarea  ${answer_data.data.answer}
  Дочекатися І Клікнути  //*[contains(text(), "${question_id}")]/../descendant::button[@name="answer_question_submit"]
  Wait Until Page Contains  ${answer_data.data.answer}  30
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"/tender/view/")]

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  Тендеру

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  ${item_id}

Задати запитання на лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  ${lot_id}

Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  Відповісти на питання  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}

###############################################################################################################
############################################    ВИМОГИ    #####################################################
###############################################################################################################

Створити вимогу про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${document}=${None}  ${related_to}=Тендеру
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/complaints")]
  Toggle Sidebar
  Wait Until Keyword Succeeds  10 x  400 ms  Run Keywords
  ...  Дочекатися І Клікнути  xpath=//a[contains(@href, "status=claim")]
  ...  AND  Wait Until Element Is Visible  xpath=//select[@name="Complaint[relatedLot]"]/option[contains(text(), "${related_to}")]
  ${related_to}=  Get Text  xpath=//select[@name="Complaint[relatedLot]"]/option[contains(text(), "${related_to}")]
  Input Text  name=Complaint[title]  ${claim.data.title}
  Input Text  name=Complaint[description]  ${claim.data.description}
  Wait And Select From List By Label  name=Complaint[relatedLot]  ${related_to}
  Run Keyword If  '${document}' != '${None}'  Run Keywords
  ...  Choose File  xpath=//input[@type="file"]  ${document}
  ...  AND  Input Text  xpath=//input[contains(@name, "[title]") and contains(@name,"documents")]  ${document.split("/")[-1]}
  Дочекатися І Клікнути  name=complaint_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу
  Wait Until Keyword Succeeds  10 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain Element  xpath=//*[contains(text(),"${claim.data.title}")]/ancestor::*[@class="mk-question"]/descendant::*[@data-test-id="complaint.status" and contains(text(),"вимога")]
  ${complaintID}=   Get Text   xpath=(//*[@data-test-id="complaint.complaintID"])[1]
  [Return]  ${complaintID}

Підтвердити вирішення вимоги про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${confirmation_data}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/complaints")]
  Run Keyword If  ${confirmation_data.data.satisfied}  Дочекатися І Клікнути  xpath=//button[@name="complaint_resolved"]
  ...  ELSE  Дочекатися І Клікнути  xpath=//button[@name="claim_satisfied_false"]
  Wait Until Keyword Succeeds  30 x  1 s  Page Should Contain Element  xpath=//*[@data-test-id="complaint.satisfied"]

Створити вимогу про виправлення умов лоту
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${lot_id}  ${document}=${None}
  ${complaintID}=  allbiz.Створити вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${claim}  ${document}  ${lot_id}
  [Return]  ${complaintID}

Підтвердити вирішення вимоги про виправлення умов лоту
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${confirmation_data}
  allbiz.Підтвердити вирішення вимоги про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${complaintID}  ${confirmation_data}

Відповісти на вимогу про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}
  allbiz.Відповісти на вимогу  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}

Відповісти на вимогу про виправлення умов лоту
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}
  allbiz.Відповісти на вимогу  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}

Відповісти на вимогу про виправлення визначення переможця
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}  ${award_index}
  allbiz.Відповісти на вимогу  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}

Відповісти на вимогу
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${answer_data}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Run Keyword If  "переможця" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/complaints")]
  Wait Until Page Does Not Contain  Специфікація закупівлі
  Wait Until Keyword Succeeds  10 x  60 s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain  ${complaintID}
  Run Keyword If  "переможця" in "${TEST_NAME}"  Input Text  xpath=//*[contains(text(),"${complaintID}")]/../descendant::textarea[contains(@name,"resolution")]  ${answer_data.data.resolution}
  ...  ELSE  Input Text  xpath=//*[contains(text(),"${complaintID}")]/../descendant::textarea[contains(@name,"[resolution]")]  ${answer_data.data.resolution}
  Дочекатися І Клікнути  xpath=//*[contains(text(),"${complaintID}")]/../descendant::input[@value="${answer_data.data.resolutionType}"]/..
  Дочекатися І Клікнути  name=answer_complaint_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Створити чернетку вимоги про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${claim}
  ${complaint_id}=  allbiz.Створити вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${claim}
  [Return]  ${complaint_id}

Скасувати вимогу про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${cancellation_data}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/complaints")]
  Дочекатися І Клікнути  xpath=//input[@class="cancel_checkbox"]/..
  Ввести Текст  xpath=//*[contains(@name, "[cancellationReason]")]  ${cancellation_data.data.cancellationReason}
  Дочекатися І Клікнути  xpath=//button[@name="complaint_cancelled"]

Створити чернетку вимоги про виправлення умов лоту
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${lot_id}
  ${complaint_id}=  allbiz.Створити вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${claim}  ${None}  ${lot_id}
  [Return]  ${complaint_id}

Скасувати вимогу про виправлення умов лоту
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${cancellation_data}
  allbiz.Скасувати вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${complaintID}  ${cancellation_data}

Перетворити вимогу про виправлення умов закупівлі в скаргу
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${escalating_data}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Run Keyword If  "переможця" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/complaints")]
  Wait Until Page Does Not Contain  Специфікація закупівлі
  Дочекатися І Клікнути  xpath=//*[contains(text(),"${complaintID}")]/../descendant::button[@name="complaint_convert_to_claim"]
  Sleep  5

Перетворити вимогу про виправлення умов лоту в скаргу
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${escalating_data}
  allbiz.Перетворити вимогу про виправлення умов закупівлі в скаргу  ${username}  ${tender_uaid}  ${complaintID}  ${escalating_data}

Створити вимогу про виправлення визначення переможця
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${award_index}  ${document}=${None}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Toggle Sidebar
  Дочекатися І Клікнути  xpath=//a[contains(@href,"tender/qualification")]
  Дочекатися І Клікнути  xpath=//a[contains(@href, "status=claim")]
  Input Text  name=Complaint[title]  ${claim.data.title}
  Input Text  name=Complaint[description]  ${claim.data.description}
  Run Keyword If  '${document}' != '${None}'  Run Keywords
  ...  Choose File  xpath=//input[@type="file"]  ${document}
  ...  AND  Input Text  xpath=//input[contains(@name, "[title]") and contains(@name,"documents")]  ${document.split("/")[-1]}
  Дочекатися І Клікнути  name=complaint_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу
  Wait Until Keyword Succeeds  10 x  30 s  Page Should Contain Element  xpath=//*[contains(text(),"${claim.data.title}")]/preceding-sibling::*[@data-test-id="complaint.complaintID"]
  ${complaintID}=   Get Text   xpath=(//*[@data-test-id="complaint.complaintID"])[last()]
  [Return]  ${complaintID}

Підтвердити вирішення вимоги про виправлення визначення переможця
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${confirmation_data}  ${award_index}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Дочекатися І Клікнути  xpath=//a[contains(@href,"tender/qualification")]
  Дочекатися І Клікнути  xpath=//button[@name="award_claim_resolved"]
  Wait Until Keyword Succeeds  30 x  1 s  Page Should Contain Element  xpath=//*[@data-test-id="complaint.satisfied"]

Створити чернетку вимоги про виправлення визначення переможця
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${award_index}
  ${complaint_id}=  allbiz.Створити вимогу про виправлення визначення переможця   ${username}  ${tender_uaid}  ${claim}  ${award_index}
  [Return]  ${complaint_id}

Скасувати вимогу про виправлення визначення переможця
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${cancellation_data}  ${award_index}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Дочекатися І Клікнути  xpath=//a[contains(@href,"tender/qualification")]
  Дочекатися І Клікнути  xpath=//input[@class="cancel_checkbox"]/..
  Ввести Текст  xpath=//*[contains(@name, "[cancellationReason]")]  ${cancellation_data.data.cancellationReason}
  Дочекатися І Клікнути  xpath=//button[@name="complaint_cancelled"]

Перетворити вимогу про виправлення визначення переможця в скаргу
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${escalating_data}  ${award_index}
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Run Keyword If  "переможця" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/complaints")]
  Wait Until Page Does Not Contain  Специфікація закупівлі
  Дочекатися І Клікнути  xpath=//*[contains(text(),"${complaintID}")]/../descendant::button[@name="award_claim_convert_to_pending"]
  Sleep  5

###############################################################################################################
###################################    ВІДОБРАЖЕННЯ ІНФОРМАЦІЇ    #############################################
###############################################################################################################

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  Run Keyword If  'title' in '${field_name}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
  Run Keyword If  '${field_name}' == 'status'  Reload Page
  Run Keyword If  '${field_name}' == 'qualificationPeriod.endDate'  Wait Until Keyword Succeeds  10 x  60 s  Run Keywords
  ...  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ...  AND  Page Should Contain Element  xpath=//*[@data-test-id="qualificationPeriod.endDate"]
  ${value}=  Run Keyword If  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на allbiz
  ...  ELSE IF  'qualifications' in '${field_name}'  Отримати інформацію із кваліфікації  ${username}  ${tender_uaid}  ${field_name}
  ...  ELSE IF  'awards' in '${field_name}'  Отримати інформацію із аварду  ${username}  ${tender_uaid}  ${field_name}
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//*[@data-test-id="items.quantity"]
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на allbiz
  ...  ELSE IF  'items' in '${field_name}'  Get Text  xpath=//*[@data-test-id="${field_name.replace('[0]', '')}"]
  ...  ELSE IF  '${field_name}' == 'cause'  Get Element Attribute  xpath=//*[@data-test-id="${field_name}"]@data-test-cause
  ...  ELSE IF  '${field_name}' == 'procuringEntity.identifier.legalName'  Get Text  xpath=//*[@data-test-id="procuringEntity.name"]
  ...  ELSE IF  '${field_name}' == 'procuringEntity.identifier.scheme'  Get Element Attribute  xpath=//*[@data-test-id="procuringEntity.identifier.scheme"]@value
  ...  ELSE IF  '${field_name}' == 'documents[0].title'  Get Text  xpath=//a[contains(@href,"docs-sandbox")]
  ...  ELSE IF  '${field_name}' == 'contracts[0].status'  Отримати статус контракта  ${username}  ${tender_uaid}
  ...  ELSE  Get Text  xpath=//*[@data-test-id="${field_name}"]
  ${value}=  adapt_view_tender_data  ${value}  ${field_name}
  [Return]  ${value}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на allbiz
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на allbiz
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//*[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@data-test-id='items.quantity']
  ...  ELSE  Get Text  xpath=//*[contains(text(), '${item_id}')]/ancestor::div[@class="item-block"]/descendant::*[@data-test-id='items.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [Return]  ${value}

Отримати інформацію із лоту
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${value}=  Run Keyword If  'minimalStep' in '${field_name}' and 'TaxIncluded' not in '${field_name}'  Get Text  xpath=//*[@data-test-id="lots.minimalStep.amount"]
  ...  ELSE IF  'value' in '${field_name}'  Get Text  xpath=//*[contains(text(),"${lot_id}")]/ancestor::div[@class="item-inf_txt"]/descendant::*[@data-test-id='lots.value.amount']
  ...  ELSE  Get Text  xpath=//*[contains(text(),"${lot_id}")]/ancestor::div[@class="item-inf_txt"]/descendant::*[@data-test-id='lots.${field_name}']
  ${value}=  adapt_view_lot_data  ${value}  ${field_name}
  [Return]  ${value}

Отримати інформацію із нецінового показника
  [Arguments]  ${username}  ${tender_uaid}  ${feature_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${value}=  Run Keyword If
  ...  'featureOf' in '${field_name}'  Get Element Attribute  xpath=//*[contains(text(),"${feature_id}")]/ancestor::div[@class="feature"]/descendant::*[@data-test-id='feature.${field_name}']@rel
  ...  ELSE  Get Text  xpath=//*[contains(text(),"${feature_id}")]/ancestor::div[@class="feature"]/descendant::*[@data-test-id='feature.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [Return]  ${value}

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  ${file_title}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  [Return]  ${file_title.split('/')[-1]}

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  ${file_name}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  ${url}=   Get Element Attribute   xpath=//a[contains(text(),'${doc_id}')]@href
  custom_download_file   ${url}  ${file_name.split('/')[-1]}  ${OUTPUT_DIR}
  [Return]  ${file_name.split('/')[-1]}

Отримати документ до лоту
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${doc_id}
  ${file_name}=   allbiz.Отримати документ   ${username}  ${tender_uaid}  ${doc_id}
  [Return]  ${file_name}

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/questions")]
  Wait Until Element Is Not Visible  xpath=//*[@data-test-id="items.description"]
  Wait Until Keyword Succeeds  5 x  60 s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain  ${question_id}
  ${value}=  Get Text  xpath=//*[contains(text(), "${question_id}")]/ancestor::div[contains(@class, "mk-question")]/descendant::*[@data-test-id="question.${field_name.replace('[0]', '')}"]
  [Return]  ${value}

Отримати інформацію із скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${field_name}  ${award_index}=${None}
  Run keyword If  '${field_name}' == 'status' and '${ROLE}' == 'viewer'  Sleep  120
  allbiz.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Run Keyword If  "ignored" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/protokol")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE IF  "переможця" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/complaints")]
  Wait Until Page Does Not Contain Element  xpath=//*[@data-test-id="items.description"]
  Wait Until Keyword Succeeds  10 x  60s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain Element  xpath=//*[contains(text(), "${complaintID}")]/ancestor::div[@class="mk-question"]/descendant::*[@data-test-id="complaint.${field_name}"]
  ${value}=  Get Text  xpath=//*[contains(text(), "${complaintID}")]/ancestor::div[@class="mk-question"]/descendant::*[@data-test-id="complaint.${field_name}"]
  ${value}=  convert_string_from_dict_allbiz   ${value}
  [Return]  ${value}

Отримати інформацію із документа до скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${doc_id}  ${field_name}  ${award_id}=${None}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Run Keyword If  "переможця" in "${TEST_NAME}"  Run Keywords
  ...    Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ...    AND  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/complaints")]
  ${value}=  allbiz.Отримати інформацію із документа  ${username}  ${tender_uaid}  ${doc_id}  ${field_name}
  [Return]  ${value}

Отримати документ до скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${doc_id}  ${award_id}=${None}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href, "/complaints")]
  ${value}=  allbiz.Отримати документ   ${username}  ${tender_uaid}  ${doc_id}
  [Return]  ${value}

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${is_edited}=  Run Keyword And Return Status  Page Should Contain  Замовником внесено зміни в умови
  ${value}=  Run Keyword If  ${is_edited} == ${True}  Set Variable  invalid
  ...  ELSE  Get Element Attribute  xpath=//input[contains(@name,"[value][amount]")]@value
  ${value}=  Run Keyword If  "value.amount" in "${field}"  Convert To Number  ${value}
  ...  ELSE  Set Variable  ${value}
  [Return]  ${value}

Отримати інфорцію про замовника
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${address}=  Run Keyword If  "address" in "${field_name}"  Get Text  xpath=//*[@data-test-id="procuringEntity.address"]
  ${value}=  Set Variable If  "procuringEntity.address.countryName" in "${field_name}"  ${address.split(" ")[0]}
  ...  "procuringEntity.address.locality" in "${field_name}"  ${address.split(" ")[2]}
  ...  "procuringEntity.address.postalCode" in "${field_name}"  ${address.split(" ")[1]}
  ...  "procuringEntity.address.region" in "${field_name}"  ${address.split(" ")[2]}
  ...  "procuringEntity.address.streetAddress" in "${field_name}"  ${address.split(" ")[3:]}
  [Return]  ${value}

Отримати інформацію із кваліфікації
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${index_str}=  Set Variable  ${field_name[15]}
  ${index_int}=  Convert To Integer  ${index_str}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/euprequalification")]
  ${value}=  Get Text  xpath=//*[@data-mtitle="№" and contains(text(),"${index_int + 1}")]/following-sibling::*[@data-mtitle="Статус:"]
  [Return]  ${value}

Отримати інформацію із аварду
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${is_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/protokol")]
  Run Keyword If  ${is_visible}  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/protokol")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Toggle Sidebar
  Run Keyword If  '${field_name}' == 'awards[0].documents[0].title'  Клікнути і Дочекатися Елемента  xpath=//button[contains(@id,"modal-qualification")]  xpath=//div[@class="modal-dialog "]
  ...  ELSE IF  'suppliers' in '${field_name}'  Клікнути і Дочекатися Елемента   xpath=//*[contains(@id,"btn-company-identifier")]  xpath=//div[@class="modal-dialog "]
  ...  ELSE IF  '${field_name}' == 'awards[0].complaintPeriod.endDate'  Дочекатися І Клікнути  xpath=//*[@class="page-panel"]/descendant::a[contains(@href,"tender/qualification-complaints")]
  ${value}=  Run Keyword If  '${field_name}' == 'awards[0].documents[0].title'  Get Text  xpath=(//a[contains(@href,"docs-sandbox")])[1]
  ...  ELSE IF  'status' in '${field_name}'  Get Text  xpath=//span[contains(@data-test-id, "status")]
  ...  ELSE IF  'amount' in '${field_name}'  Get Text  xpath=//*[@data-mtitle="Пропозицiя:"]/b
  ...  ELSE IF  'currency' in '${field_name}'  Get Text  xpath=//*[@data-mtitle="Пропозицiя:"]
  ...  ELSE IF  'value' in '${field_name}'  Get Text  xpath=//*[contains(text(), "ПДВ")]
  ...  ELSE IF  '${field_name}' == 'awards[0].complaintPeriod.endDate'  Get Text  xpath=//div[contains(text(),"Завершення періоду подання вимог")]/following-sibling::div[1]
  ...  ELSE IF  'legalName' in '${field_name}'  Get Text  xpath=//*[@data-test-id="awards.suppliers.name"]
  ...  ELSE  Get Text  xpath=//*[@data-test-id="${field_name.replace("[0]","")}"]
  [Return]  ${value.split(" - ")[-1]}

Отримати статус контракта
  [Arguments]  ${username}  ${tender_uaid}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${is_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/protokol")]
  Run Keyword If  ${is_visible}  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/protokol")]
  ...  ELSE  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  ${status}=  Run Keyword And Return Status  Run Keywords
  ...  Click Element  xpath=//button[text()="Контракт"]
  ...  AND  Wait Element Animation  xpath=//*[contains(@id,"modal-award")]/descendant::button[@class="close"]
  ...  AND  Page Should Contain  Договір активовано
  ${value}=  Set Variable If  ${status}  active  pending
  ${is_modal_open}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//*[contains(@id,"modal-award")]/descendant::button[@class="close"]
  Run Keyword If  ${is_modal_open}  Run Keywords
  ...  Click Element  xpath=//*[contains(@id,"modal-award")]/descendant::button[@class="close"]
  ...  AND  Wait Element Animation  xpath=//*[contains(@id,"modal-award")]/descendant::button[@class="close"]
  Click Element  xpath=//*[@id="slidePanel"]/descendant::*[contains(@href,"tender/view")]
  [Return]  ${value}

###############################################################################################################
#######################################    ПОДАННЯ ПРОПОЗИЦІЙ    ##############################################
###############################################################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}  ${lots_ids}=${None}  ${features_ids}=${None}
  ${meat}=  Evaluate  ${tender_meat} + ${lot_meat} + ${item_meat}
  ${selfeligible_status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${bid.data}  selfEligible
  ${selfqualified_status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${bid.data}  selfQualified
  ${lots_status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${bid.data}  lotValues
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Sleep  2
  Run Keyword If  ${lots_status}  Ввести пропозицію для лотової зкупівлі  ${bid}
  ...  ELSE  ConvToStr And Input Text  name=Bid[value][amount]  ${bid.data.value.amount}
  Run Keyword If  ${meat} > 0  Вибрати нецінові показники в пропозиції  ${bid}
  Run Keyword If  ${selfeligible_status}  Дочекатися І Клікнути  xpath=//input[@id="bid-selfeligible"]/..
  Run Keyword If  ${selfqualified_status}  Дочекатися І Клікнути  xpath=//input[@id="bid-selfqualified"]/..
  Подати Пропозицію Без Накладення ЕЦП
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]

Подати Пропозицію Без Накладення ЕЦП
  Wait Until Element Is Not Visible  xpath=//*[@class="spinner"]
  Дочекатися І Клікнути  xpath=//button[@id="submit_bid"]
  Run Keyword And Ignore Error  Wait Until Keyword Succeeds  10 x  1 s  Run Keywords
  ...  Click Element  xpath=(//*[@data-dismiss="modal"])[last()]
  ...  AND  Wait Until Page Does Not Contain  Зверніть увагу  10

Ввести пропозицію для лотової зкупівлі
  [Arguments]  ${bid}
  ${number_of_lots}=  Get Length  ${bid.data.lotValues}
  :FOR  ${lot_index}  IN RANGE  ${number_of_lots}
  \  ConvToStr And Input Text  name=Bid[lotValues][${bid.data.lotValues[${lot_index}].relatedLot}][value][amount]  ${bid.data.lotValues[${lot_index}].value.amount}

Вибрати нецінові показники в пропозиції
  [Arguments]  ${bid}
  ${number_of_feature}=  Get Length  ${bid.data.parameters}
  :FOR  ${feature_index}  IN RANGE  ${number_of_feature}
  \  ${value}=  Convert To Integer  ${bid.data.parameters[${feature_index}]["value"]}
  \  ${label}=  Get Text  xpath=//option[@value="${bid.data.parameters[${feature_index}]["code"]}" and @rel="${value * 100}"]
  \  Wait And Select From List By Label  xpath=//option[@value="${bid.data.parameters[${feature_index}]["code"]}"]/ancestor::select  ${label}


Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Execute Javascript  window.confirm = function(msg) { return true; }
  Дочекатися І Клікнути  xpath=//button[@name="delete_bids"]

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${status}=  Run Keyword And Return Status  Page Should Not Contain  Замовником внесено зміни в умови
  Run Keyword If  ${status}  ConvToStr And Input Text  xpath=//input[contains(@name,'[value][amount]')]  ${fieldvalue}
  ...  ELSE  Подати Пропозицію Без Накладення ЕЦП
  Подати Пропозицію Без Накладення ЕЦП
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//div[contains(@class, 'alert-success')]

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=technicalSpecifications
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Choose File  xpath=(//input[@type="file"])[last()]  ${path}
  ${doc_type_status}=  Run Keyword And Return Status  Wait Until Element Is visible  xpath=(//select[contains(@name,"[documentType]")])[last()]  10
  Run Keyword If  ${doc_type_status}  Wait And Select From List By Value  xpath=(//select[contains(@name,"[documentType]")])[last()]  ${doc_type}
  ${related_status}=  Run Keyword And Return Status  Element Should Be Visible  xpath=(//select[contains(@name,"[relatedItem]")])[last()]
  Run Keyword If  ${related_status}  Wait And Select From List By Value  xpath=(//select[contains(@name,"[relatedItem]")])[last()]  tender
  Подати Пропозицію Без Накладення ЕЦП
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  Дочекатися завантаження документу

Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${doc_id}
  Wait Until Keyword Succeeds   30 x   10 s   Дочекатися вивантаження файлу до ЦБД
  Execute Javascript  window.confirm = function(msg) { return true; };
  Choose File  xpath=//div[contains(text(), 'Замiнити')]/form/input  ${path}
  Подати Пропозицію Без Накладення ЕЦП
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  Дочекатися завантаження документу

Змінити документацію в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${doc_data}  ${doc_id}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=(//*[@class="confidentiality"])[last()]/..
  Input Text  xpath=(//textarea[contains(@name,"confidentialityRationale")])[last()]  ${doc_data.data.confidentialityRationale}
  Подати Пропозицію Без Накладення ЕЦП
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]

###############################################################################################################
###########################################    КВАЛІФІКАЦІЯ    ################################################
###############################################################################################################

Завантажити документ у кваліфікацію
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${qualification_num}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${qualification_num}=  Convert To Integer  ${qualification_num}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/euprequalification")]
  Click Element  xpath=//*[@data-mtitle="№" and contains(text(),"${qualification_num + 1}")]/../descendant::*[contains(@id,"modal-qualification-button")]
  Wait Element Animation  xpath=//*[contains(@id,"modal-qualification") and contains(@class,"modal in")]/descendant::input[@type="file"]
  Choose File  xpath=//*[contains(@id,"modal-qualification") and contains(@class,"modal in")]/descendant::input[@type="file"]  ${document}

Завантажити документ рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${award_num}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Дочекатися І Клікнути  xpath=//*[contains(@id,"modal-award-qualification-button")]
  Wait Element Animation  xpath=//select[@class="choose_prequalification"]
  Select From List By Value  xpath=//select[@class="choose_prequalification"]  active
  Wait Until Keyword Succeeds  10 x  400 ms  Page Should Contain Element  xpath=(//input[@type="file"])[last()]
  Choose File  xpath=//*[@class="active"]/descendant::input[@type="file"]  ${document}
  Дочекатися І Клікнути  xpath=//input[contains(@id,"qualified")]/..
  Дочекатися І Клікнути  xpath=//input[contains(@id,"eligible")]/..
  Дочекатися І Клікнути  xpath=(//*[@name="send_prequalification"])[1]

Підтвердити постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  Log  Необхідні дії було виконано у "Завантажити документ рішення кваліфікаційної комісії"

Підтвердити кваліфікацію
  [Arguments]  ${username}  ${tender_uaid}  ${qualification_num}
  ${document}=  get_upload_file_path
  ${qualification_num}=  Set Variable If  "${qualification_num}" == "-1"  1  ${qualification_num}  # Needed in cause of getting -1 for second qualifyer from Quinta`s code
  allbiz.Завантажити документ у кваліфікацію  ${username}  ${document}  ${tender_uaid}  ${qualification_num}
  ${qualification_num}=  Convert To Integer  ${qualification_num}
  Дочекатися І Клікнути  xpath=//*[contains(@id,"modal-qualification") and contains(@class,"modal in")]/descendant::input[contains(@id,"qualified")]/..
  Дочекатися І Клікнути  xpath=//*[contains(@id,"modal-qualification") and contains(@class,"modal in")]/descendant::input[contains(@id,"eligible")]/..
  Дочекатися І Клікнути  xpath=//*[contains(@id,"modal-qualification") and contains(@class,"modal in")]/descendant::button[@name="send_prequalification"]
  Wait Until Keyword Succeeds  10 x  1 s  Run Keywords
  ...  Page Should Contain  Зверніть увагу
  ...  AND  Wait Element Animation  xpath=//*[@class="modal-dialog"]/descendant::*[contains(text(),"Накласти ЕЦП")]
  Накласти ЄЦП

Скасувати кваліфікацію
  [Arguments]  ${username}  ${tender_uaid}  ${qualification_num}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  name=cancel_prequalification

Затвердити остаточне рішення кваліфікації
  [Arguments]  ${username}  ${tender_uaid}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/euprequalification")]
  Дочекатися І Клікнути  xpath=//button[@name="prequalification_next_status"]
  Wait Until Page Contains  Оскарження прекваліфікації

Підтвердити підписання контракту
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  Sleep  60
  ${document}=  get_upload_file_path
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Дочекатися І Клікнути  xpath=//div[@id="slidePanel"]/descendant::a[contains(@href,"tender/award")]
  Wait Until Keyword Succeeds  5 x  0.5 s  Дочекатися І Клікнути  xpath=//button[text()="Контракт"]
  Wait Until Element Is Visible  xpath=//*[text()="Додати документ"]
  Choose File  xpath=//input[@type="file"]  ${document}
  Дочекатися І Клікнути  xpath=//button[text()='Завантажити']
  Wait Until Keyword Succeeds  20 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Element Should Be Visible  xpath=//button[text()="Контракт"]
  ...  AND  Click Element  xpath=//button[text()="Контракт"]
  ...  AND  Page Should Not Contain  Файл завантажується...
  Wait Element Animation  xpath=//*[contains(@name,"[dateSigned]")]
  Mouse Down  xpath=//*[contains(@name,"[dateSigned]")]
  Input Text  xpath=//input[contains(@name,"[contractNumber]")]  777
  Input Text  name=ContractPeriod[0][startDate]  01/06/2018 00:00:00
  Input Text  name=ContractPeriod[0][endDate]  09/06/2018 00:00:00
  Choose Ok On Next Confirmation
  Дочекатися І Клікнути  xpath=//button[text()='Активувати']
  Confirm Action
  Run Keyword If  '${MODE}' != 'belowThreshold'  Run Keywords
  ...  Wait Element Animation  xpath=//*[@class="modal-dialog"]/descendant::button[contains(text(),"Накласти ЕЦП")]
  ...  AND  Накласти ЄЦП

###############################################################################################################
##############################################    АУКЦІОН    ##################################################
###############################################################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}=  Wait Until Keyword Succeeds  10 x  60 s  Дочекатися посилання на аукціон
  [Return]  ${auction_url}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  allbiz.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${current_url}=  Get Location
  Run Keyword If  ${NUMBER_OF_LOTS} == 0  Execute Javascript  window['url'] = null; $.get( "${host}/seller/tender/updatebid", { id: "${current_url.split("/")[-1]}"}, function(data){ window['url'] = data.data.participationUrl },'json');
  ...  ELSE  Execute Javascript  window['url'] = null; $.get( "${host}/seller/tender/updatebid", { id: "${current_url.split("/")[-1]}"}, function(data){ window['url'] = data.data.lotValues[0].participationUrl },'json');
  Wait Until Keyword Succeeds  20 x  1 s  JQuery Ajax Should Complete
  ${auction_url}=  Execute Javascript  return window['url'];
  [Return]  ${auction_url}

###############################################################################################################

ConvToStr And Input Text
  [Arguments]  ${locator}  ${smth_to_input}
  ${smth_to_input}=  Convert To String  ${smth_to_input}
  Scroll To Element  ${locator}
  Input Text  ${locator}  ${smth_to_input}

Conv And Select From List By Value
  [Arguments]  ${locator}  ${smth_to_select}
  ${smth_to_select}=  Convert To String  ${smth_to_select}
  ${smth_to_select}=  convert_string_from_dict_allbiz  ${smth_to_select}
  Wait And Select From List By Value  ${locator}  ${smth_to_select}

Input Date
  [Arguments]  ${elem_locator}  ${date}
  ${date}=  convert_datetime_to_allbiz_format  ${date}
  Input Text  ${elem_locator}  ${date}

Дочекатися вивантаження файлу до ЦБД
  Reload Page
  Wait Until Element Is Visible   xpath=//div[contains(text(), 'Замiнити')]

Ввести текст
  [Arguments]  ${locator}  ${text}
  Wait Until Element Is Visible  ${locator}
  Input Text  ${locator}  ${text}

Дочекатися і Клікнути
  [Arguments]  ${locator}
  Wait Until Element Is Visible  ${locator}
  Scroll To Element  ${locator}
  Click Element  ${locator}

Клікнути і Дочекатися Елемента
  [Arguments]  ${locator}  ${wait_for_locator}
  Scroll To Element  ${locator}
  Click Element  ${locator}
  Wait Until Page Contains Element  ${wait_for_locator}
  Sleep  2

Дочекатися посилання на аукціон
  ${auction_url}=  Get Element Attribute  xpath=(//a[contains(@href, "auction-sandbox.openprocurement.org/")])[1]@href
  Should Not Be Equal  ${auction_url}  javascript:void(0)
  [Return]  ${auction_url}

Wait And Select From List By Value
  [Arguments]  ${locator}  ${value}
  Wait Until Keyword Succeeds  10 x  1 s  Select From List By Value  ${locator}  ${value}

Wait And Select From List By Label
  [Arguments]  ${locator}  ${value}
  Wait Until Keyword Succeeds  10 x  1 s  Select From List By Label  ${locator}  ${value}

JQuery Ajax Should Complete
  ${active}=  Execute Javascript  return jQuery.active
  Should Be Equal  "${active}"  "0"

Scroll To Element
  [Arguments]  ${locator}
  Wait Until Page Contains Element  ${locator}  10
  ${elem_vert_pos}=  Get Vertical Position  ${locator}
  Execute Javascript  window.scrollTo(0,${elem_vert_pos - 300});

Накласти ЄЦП
  Wait Until Page Contains  Накласти ЕЦП
  Дочекатися І Клікнути  xpath=//*[@class="modal-dialog"]/descendant::*[contains(text(),"Накласти ЕЦП")]
  Wait Until Keyword Succeeds  30 x  1 s  Page Should Contain Element  id=SignDataButton
  Wait Until Page Does Not Contain  Зчитування ключа  30
  Execute Javascript  $(".fade.modal.in").scrollTop(2000)
  ${status}=  Run Keyword And Return Status  Page Should Contain  Оберіть файл з особистим ключем (зазвичай з ім'ям Key-6.dat) та вкажіть пароль захисту
  Run Keyword If  ${status}  Run Keywords
  ...  Wait And Select From List By Label  id=CAsServersSelect  Тестовий ЦСК АТ "ІІТ"
  ...  AND  Execute Javascript  var element = document.getElementById('PKeyFileInput'); element.style.visibility="visible";  $(".fade.modal.in").scrollTop(2000)
  ...  AND  Choose File  id=PKeyFileInput  ${CURDIR}/Key-6.dat
  ...  AND  Input text  id=PKeyPassword  qwerty
  ...  AND  Дочекатися І Клікнути  id=PKeyReadButton
  ...  AND  Wait Until Page Contains  Горобець  10
  Дочекатися І Клікнути  id=SignDataButton
  Wait Until Keyword Succeeds  60 x  1 s  Page Should Not Contain Element  id=SignDataButton  120

Toggle Sidebar
  ${is_sidebar_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//div[contains(@class,"mk-slide-panel_body")]
  Run Keyword If  ${is_sidebar_visible}  Run Keywords
  ...  Click Element  id=slidePanelToggle
  ...  AND  Wait Element Animation  xpath=//div[@class="title"]

Wait Element Animation
  [Arguments]  ${locator}
  Set Test Variable  ${prev_vert_pos}  0
  Wait Until Keyword Succeeds  20 x  500 ms  Position Should Equals  ${locator}

Position Should Equals
  [Arguments]  ${locator}
  ${current_vert_pos}=  Get Vertical Position  ${locator}
  ${status}=  Run Keyword And Return Status  Should Be Equal  ${prev_vert_pos}  ${current_vert_pos}
  Set Test Variable  ${prev_vert_pos}  ${current_vert_pos}
  Should Be True  ${status}
