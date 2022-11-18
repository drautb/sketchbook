import ipaddress
import typer

from rich import print
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.console import Group
from rich.layout import Layout

def main(network_string):
    addr = ipaddress.ip_address(network_string.split('/')[0])
    network = ipaddress.ip_network(network_string, strict=False)

    layout = Layout()
    layout.split_row(
        Layout(build_breakdown("Provided", addr, network), size=39),
        Layout(build_breakdown("Begin", network[0], network), size=39),
        Layout(build_breakdown("End", network[-1], network), size=39))

    p = Panel(layout, expand=False, width=121, height=6, title=f"Decomposition of [green]{addr}[/green]/[yellow]{network.prefixlen}[/yellow]")
    print(p)


def build_breakdown(label, addr, network):
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

    return Panel(Group(
        f"{octets[0]: >8}.{octets[1]: >8}.{octets[2]: >8}.{octets[3]: >8}",
        bit_string
    ), expand=False, title=f"[bold green]{label}[/bold green]")



if __name__ == "__main__":
    typer.run(main)

