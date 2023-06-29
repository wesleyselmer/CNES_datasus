*** Settings ***
Documentation       Baixar CSV com as localidades e baixar informações de saúde do site do CNES.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Desktop
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Windows
Library             Collections
Library             String
Resource            estados.robot


*** Variables ***
@{info_hospitais}       @{EMPTY}
${inputFile}=           ${EMPTY}
${DOWNLOAD_DIR}=        ${CURDIR}\\download
${DOWNLOAD_FILE}=       fichaCompletaEstabelecimento.pdf
${paginaInicial}=       https://cnes.datasus.gov.br/pages/estabelecimentos/consulta.jsp


*** Tasks ***
Download de informações CNES
    Tratar arquivo CSV
    Abrir página do CNES
    Obter informações
    Navegar para tela inicial
    Salvar PDF's individuais
    [Teardown]    Fechar Browser


*** Keywords ***
Tratar arquivo CSV
    ${csv}=    Get File    ${DOWNLOAD_DIR}\\LOCALIDADES.CSV
    @{read}=    Create List    ${csv}
    @{lines}=    Split To Lines    @{read}    1

    FOR    ${line}    IN    @{lines}
        @{split}=    Split String    ${line}    ,
        ${estadoCompleto}=    Get From Dictionary    &{estados}    ${split}[0]
        Buscar resultados CNES    ${estadoCompleto}    ${${split}[1]}
    END

Abrir página do CNES
    Set Download Directory    ${DOWNLOAD_DIR}
    Open Available Browser    ${paginaInicial}
    Maximize Browser Window
    Sleep    5s

Obter informações
    FOR    ${counter}    IN RANGE    1    5
        Copiar dados gerais dos hospitais na tela
        Avançar página
    END

Buscar resultados CNES
    [Arguments]    ${Estado}    ${Municipio}
    Wait Until Element Is Visible    xpath: //*[@ng-model="Estado"]
    Select From List By Label    xpath: //*[@ng-model="Estado"]    ${Estado}
    Sleep    5s
    Wait Until Element Is Visible    xpath: //*[@ng-model="Municipio"]
    Wait Until Element Is Not Visible    xpath: //*[@ng-model="Municipio"][@disabled="disabled"]
    Scroll Element Into View    xpath: //*[@ng-model="Municipio"]
    Select From List By Label    xpath: //*[@ng-model="Municipio"]    ${Municipio}
    Scroll Element Into View    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]
    Click Button    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]

Copiar dados gerais dos hospitais na tela
    Sleep    5s
    Wait Until Element Is Visible    xpath: //table[@ng-table="tableParams"]
    ${linhas}=    Get Element Count    xpath: //table[@ng-table="tableParams"]/tbody/tr

    FOR    ${contador_linha}    IN RANGE    1    ${linhas}
        ${UF}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[1]
        ${Municipio}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[2]
        ${CNES}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[3]
        ${NomeFantasia}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[4]
        ${NaturezaJuridica}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[5]
        ${Gestao}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[6]
        ${Atende_SUS}=    RPA.Browser.Selenium.Get Text
        ...    xpath: //table[@ng-table="tableParams"]/tbody/tr[${contador_linha}]/td[7]

        @{info}=    Create List
        ...    ${UF}
        ...    ${Municipio}
        ...    ${CNES}
        ...    ${NomeFantasia}
        ...    ${NaturezaJuridica}
        ...    ${Gestao}
        ...    ${Atende_SUS}
        ...
        Append To List
        ...    ${info_hospitais}
        ...    ${info}
    END

Avançar página
    Wait Until Element Is Visible    xpath: //a[@ng-switch-when="next"]
    Scroll Element Into View    xpath: //a[@ng-switch-when="next"]
    Click Element When Visible    xpath: //a[@ng-switch-when="next"]

Salvar PDF's individuais
    Abrir página do CNES
    FOR    ${hospital}    IN    @{info_hospitais}
        Pesquisar por CNES    ${hospital}[3]
        Abrir Detalhes
        Gerar PDF ficha completa
        Renomear arquivo    ${hospital}[3]
        Navegar para tela inicial
    END

Pesquisar por CNES
    [Arguments]    ${CNES}
    Wait Until Element Is Visible    id:pesquisaValue
    Input Text    id:pesquisaValue    ${CNES}
    Click Button    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]
    Sleep    5s

Abrir Detalhes
    Wait Until Element Is Visible    //*[@ng-click="abrirFicha(estab.id)"]
    Click Element    //*[@ng-click="abrirFicha(estab.id)"]
    Sleep    5s

Gerar PDF ficha completa
    Wait Until Element Is Visible    //*[@title="Imprimir ficha completa"]
    Click Element    //*[@title="Imprimir ficha completa"]
    Sleep    5s

    Wait Until Element Is Visible    //*[@id="todos"]
    Select Checkbox    //*[@id="todos"]
    Scroll Element Into View    //*[@ng-click="imprimirFichaCompleta()"]
    Click Element    //*[@ng-click="imprimirFichaCompleta()"]
    Sleep    5s

Renomear arquivo
    [Arguments]    ${CNES}
    File Should Exist    ${DOWNLOAD_DIR}/${DOWNLOAD_FILE}
    Move File    ${DOWNLOAD_DIR}/${DOWNLOAD_FILE}    ${DOWNLOAD_DIR}/${CNES}.pdf

Navegar para tela inicial
    Go To    ${paginaInicial}

Fechar Browser
    Close All Browsers
