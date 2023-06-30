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
Library             acentos.py
Resource            estados.robot


*** Variables ***
@{info_hospitais}       @{EMPTY}
${inputFile}=           ${EMPTY}
${DOWNLOAD_DIR}=        ${CURDIR}\\download
${DOWNLOAD_FILE}=       fichaCompletaEstabelecimento.pdf
${paginaInicial}=       https://cnes.datasus.gov.br/pages/estabelecimentos/consulta.jsp
${arquivoCSV}=          https://www.notion.so/signed/https%3A%2F%2Fs3-us-west-2.amazonaws.com%2Fsecure.notion-static.com%2F088724e6-2abd-4da9-bc37-dfc8c5d44e94%2FLOCALIDADES.csv?table=block&id=6415629b-ace8-46ce-b6f2-340d0afd891d&spaceId=a54fdb6a-b1aa-4215-8e8c-5377400aecfa&userId=1d5ab5ec-de2d-4d5f-b022-2d5d46abd13a&cache=v2


*** Tasks ***
Download de informações CNES
    Baixar arquivo CSV
    Tratar arquivo CSV
    Navegar para tela inicial
    Salvar PDF's individuais
    [Teardown]    Fechar Browser


*** Keywords ***
Baixar arquivo CSV
    Download    ${arquivoCSV}    ${DOWNLOAD_DIR}\\LOCALIDADES.CSV    overwrite=Yes

Tratar arquivo CSV
    ${csv}=    Get File    ${DOWNLOAD_DIR}\\LOCALIDADES.CSV
    @{read}=    Create List    ${csv}
    @{lines}=    Split To Lines    @{read}    1

    Abrir página do CNES

    FOR    ${line}    IN    @{lines}
        @{split}=    Split String    ${line}    ,
        ${sigla}=    Get From List    ${split}    0
        ${municipio}=    Get From List    ${split}    1
        ${municipio}=    Convert To Upper Case    ${municipio}
        ${municipio}=    removerAcentos    ${municipio}
        ${estadoCompleto}=    Get From Dictionary    ${estados}    ${sigla}

        Buscar resultados CNES    ${estadoCompleto}    ${municipio}
        Obter informações
    END

Abrir página do CNES
    Set Download Directory    ${DOWNLOAD_DIR}
    Open Available Browser    ${paginaInicial}
    Maximize Browser Window

Buscar resultados CNES
    [Arguments]    ${Estado}    ${Municipio}
    Wait Until Element Is Visible    xpath: //*[@ng-model="Estado"]
    Executar Keyword até obter sucesso    Select From List By Label    xpath: //*[@ng-model="Estado"]    ${Estado}

    Wait Until Element Is Visible    xpath: //*[@ng-model="Municipio"]
    Wait Until Element Is Not Visible    xpath: //*[@ng-model="Municipio"][@disabled="disabled"]
    Scroll Element Into View    xpath: //*[@ng-model="Municipio"]
    Executar Keyword até obter sucesso
    ...    Select From List By Label
    ...    xpath: //*[@ng-model="Municipio"]
    ...    ${Municipio}

    Executar Keyword até obter sucesso
    ...    Scroll Element Into View
    ...    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]
    Executar Keyword até obter sucesso    Click Button    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]

Obter informações
    FOR    ${counter}    IN RANGE    1    5
        Copiar dados gerais dos hospitais na tela
        Avançar página
    END

Salvar PDF's individuais
    FOR    ${hospital}    IN    @{info_hospitais}
        Pesquisar por CNES    ${hospital}[2]
        Abrir Detalhes
        Gerar PDF ficha completa
        Renomear arquivo    ${hospital}[2]
        Navegar para tela inicial
    END

Copiar dados gerais dos hospitais na tela
    Executar Keyword até obter sucesso    Wait Until Element Is Visible    xpath: //table[@ng-table="tableParams"]
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
    Executar Keyword até obter sucesso    Scroll Element Into View    xpath: //a[@ng-switch-when="next"]
    Executar Keyword até obter sucesso    Click Element When Visible    xpath: //a[@ng-switch-when="next"]

Pesquisar por CNES
    [Arguments]    ${CNES}
    Wait Until Element Is Visible    id:pesquisaValue
    Executar Keyword até obter sucesso    Input Text    id:pesquisaValue    ${CNES}
    Executar Keyword até obter sucesso    Click Element    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]

Abrir Detalhes
    Wait Until Element Is Visible    //*[@ng-click="abrirFicha(estab.id)"]
    Executar Keyword até obter sucesso    Click Element    //*[@ng-click="abrirFicha(estab.id)"]

Gerar PDF ficha completa
    Wait Until Element Is Visible    //*[@title="Imprimir ficha completa"]
    Executar Keyword até obter sucesso    Click Element    //*[@title="Imprimir ficha completa"]

    Wait Until Element Is Visible    //*[@id="todos"]
    Executar Keyword até obter sucesso    Select Checkbox    //*[@id="todos"]

    Executar Keyword até obter sucesso    Scroll Element Into View    //*[@ng-click="imprimirFichaCompleta()"]
    Executar Keyword até obter sucesso    Click Element    //*[@ng-click="imprimirFichaCompleta()"]

Renomear arquivo
    [Arguments]    ${CNES}
    Executar Keyword até obter sucesso    Move File    ${DOWNLOAD_DIR}/${DOWNLOAD_FILE}    ${DOWNLOAD_DIR}/${CNES}.pdf

Navegar para tela inicial
    Go To    ${paginaInicial}

Fechar Browser
    Close All Browsers

Executar Keyword até obter sucesso
    [Arguments]    ${KW}    @{KWARGS}
    Wait Until Keyword Succeeds    30s    1s    ${KW}    @{KWARGS}
