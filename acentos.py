try:
    from robot.libraries.BuiltIn import BuiltIn
    from robot.libraries.BuiltIn import _Misc
    import robot.api.logger as logger
    from robot.api.deco import keyword
    import unicodedata
    import string

    ROBOT = False
except Exception:
    ROBOT = False


@keyword("removerAcentos")
def removerAcentos(palavra: string) -> string:
    processamento = unicodedata.normalize("NFD", palavra)
    processamento = processamento.encode("ascii", "ignore")
    processamento_2 = processamento.decode("utf-8")
    return processamento_2
