*** Settings ***
Documentation       Baixar CSV com as localidades e baixar informações de saúde do site do CNES.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Desktop
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Windows
Library             Collections


*** Variables ***
@{info_hospitais}       @{EMPTY}
${paginaInicial}=       https://cnes.datasus.gov.br/pages/estabelecimentos/consulta.jsp


*** Tasks ***
Download de informações CNES
    Abrir página do CNES
    Tratar arquivo CSV
    Fechar Browser
    Salvar PDF's individuais
    [Teardown]    Fechar Browser


*** Keywords ***
Tratar arquivo CSV
    ${locais}=    Read table from CSV    LOCALIDADES.CSV
    Buscar resultados CNES
    FOR    ${counter}    IN RANGE    1    5
        Copiar dados gerais dos hospitais na tela
        Avançar página
    END

Abrir página do CNES
    Open Available Browser    ${paginaInicial}
    Maximize Browser Window
    Sleep    5s

Buscar resultados CNES
    Wait Until Element Is Visible    xpath: //*[@ng-model="Estado"]
    Select From List By Label    xpath: //*[@ng-model="Estado"]    BAHIA
    Sleep    5s
    Wait Until Element Is Visible    xpath: //*[@ng-model="Municipio"]
    Wait Until Element Is Not Visible    xpath: //*[@ng-model="Municipio"][@disabled="disabled"]
    Select From List By Label    xpath: //*[@ng-model="Municipio"]    SALVADOR
    Click Button    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]

Copiar dados gerais dos hospitais na tela
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
        Navegar para tela inicial
    END

Pesquisar por CNES
    [Arguments]    ${CNES}
    Wait Until Element Is Visible    id:pesquisaValue
    Input Text    id:pesquisaValue    ${CNES}
    Click Button    xpath: //*[@ng-click="pesquisaEstabelecimentos()"]
    Sleep    2s

Abrir Detalhes
    Wait Until Element Is Visible    //*[@ng-click="abrirFicha(estab.id)"]
    Click Element    //*[@ng-click="abrirFicha(estab.id)"]
    Sleep    5s

Gerar PDF ficha completa
    Wait Until Element Is Visible    //*[@title="Imprimir ficha completa"]
    Click Element    //*[@title="Imprimir ficha completa"]
    Sleep    2s

    Wait Until Element Is Visible    //*[@id="todos"]
    Select Checkbox    //*[@id="todos"]
    Scroll Element Into View    //*[@ng-click="imprimirFichaCompleta()"]
    Click Element    //*[@ng-click="imprimirFichaCompleta()"]
    Sleep    2s

Navegar para tela inicial
    Go To    ${paginaInicial}

Fechar Browser
    Close All Browsers
