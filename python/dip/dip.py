import ipaddress
import typer

from rich import print
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.console import Group


def main(network_string):
    addr = ipaddress.ip_address(network_string.split('/')[0])
    network = ipaddress.ip_network(network_string, strict=False)
  
    octets = f"{addr}".split('.')
    bits = '{:#b}'.format(addr)[2:]

    bit_string = "[yellow]"
    for i in range(0, 32):
        if i == network.prefixlen:
            bit_string += "[/yellow][blue]"
        if i > 0 and i % 8 == 0:
            bit_string += "."

        bit_string += bits[i]
    bit_string += "[/blue]"


    content = Group(
        "[bold green]Octets:[/bold green]",
        f"{octets[0]: >8}.{octets[1]: >8}.{octets[2]: >8}.{octets[3]: >8}",
        bit_string
    )
    p = Panel(content, expand=False, title=f"Decomposition of [green]{addr}[/green]/[yellow]{network.prefixlen}[/yellow]")
    print(p)

if __name__ == "__main__":
    typer.run(main)

