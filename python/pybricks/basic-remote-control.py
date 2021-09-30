from pybricks.parameters import Port
from pybricks.parameters import Button, Color

from pybricks.pupdevices import Remote
from pybricks.pupdevices import Motor

# Connect to the remote.
print("Connecting to remote...")
remote = Remote()
print("Connected!")

motor_a = Motor(Port.A)
motor_b = Motor(Port.B)
motor_c = Motor(Port.C)
motor_d = Motor(Port.D)

current_motors_ab = True

while True:
    pressed = ()
    while not pressed:
        pressed = remote.buttons.pressed()

    if Button.CENTER in pressed:
        while pressed:
            pressed = remote.buttons.pressed()
        current_motors_ab = not current_motors_ab

    # Set the remote light color.
    remote.light.on(Color.BLUE if current_motors_ab else Color.GREEN)

    left_motor = motor_a if current_motors_ab else motor_c
    right_motor = motor_b if current_motors_ab else motor_d
    if Button.LEFT_PLUS in pressed:
        left_motor.dc(80)
    elif Button.LEFT_MINUS in pressed:
        left_motor.dc(-80)
    else:
        left_motor.brake()

    if Button.RIGHT_PLUS in pressed:
        right_motor.dc(80)
    elif Button.RIGHT_MINUS in pressed:
        right_motor.dc(-80)
    else:
        right_motor.brake()
