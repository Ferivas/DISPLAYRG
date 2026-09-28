'Main.bas
'
'                 WATCHING Soluciones Tecnológicas
'                    Fernando Vásquez - 25.06.15
'
' Programa para almacenar los datos que se reciben por el puerto serial a una
' memoria SD
'


$version 0 , 1 , 157
$regfile = "m328pdef.dat"
$crystal = 7372800
$baud = 9600


$hwstack = 96
$swstack = 96
$framesize = 96


'Declaracion de constantes



'Configuracion de entradas/salidas
Led1 Alias Portc.2                                          'LED ROJO
Config Led1 = Output

Pinbug Alias Portb.3
Config Pinbug = Output


Datos Alias Portb.0
Config Datos = Output

Sck Alias Portb.1
Config Sck = Output

Lenac Alias Portd.2
Config Lenac = Output

Oenac Alias Portd.3
Config Oenac = Output

Lenag Alias Portd.4
Config Lenag = Output

Oenag Alias Portd.5
Config Oenag = Output

Lenar Alias Portd.6
Config Lenar = Output

Oenar Alias Portd.7
Config Oenar = Output

'Configuración de Interrupciones
'TIMER0
Config Timer0 = Timer , Prescale = 1024                     'Ints a 100Hz si Timer0=184
On Timer0 Int_timer0
Enable Timer0
Start Timer0

'TIMER1
Config Timer1 = Timer , Prescale = 1024
On Timer1 Int_timer1                                        'Ints a 1Hz
Enable Timer1
Start Timer1

'TIMER0
Config Timer2 = Timer , Prescale = 64
On Timer2 Int_timer2
Enable Timer2
Start Timer2

Config Clock = User
Config Date = Dmy , Separator = /
Date$ = "08/08/26"
Time$ = "20:28:00"


' Puerto serial 1
Open "com1:" For Binary As #1
On Urxc At_ser1
Enable Urxc


Enable Interrupts


'*******************************************************************************
'* Archivos incluidos
'*******************************************************************************
$include "RELOJ_archivos.bas"



'Programa principal

Call Inivar()


Do

   If Sernew = 1 Then                                       'DATOS SERIAL 1
      Reset Sernew
      Print #1 , "SER1=" ; Serproc
      Call Procser()
   End If

'   If Inileer = 1 Then
'      Reset Inileer

'      For Tmpb = 1 To 32
'         Print #1 , "BUF_R(" ; Tmpb ; ")=" ; Hexval(bufframr(tmpb)) ; " ; ";
'         Print #1 , "BUF_G(" ; Tmpb ; ")=" ; Hexval(bufframg(tmpb))
'      Next
'   End If

   If Newsec = 1 Then
      Reset Newsec
      Tmpstr52 = Time$
      Print #1 , Tmpstr52
      Tmpstr8 = Mid(tmpstr52 , 1 , 5 )
      Incr Tmpb
      If Tmpb.0 = 1 Then
         Mid(tmpstr8 , 3 , 1) = " "
      End If
      'Print #1 , Tmpb
      Tmpstr52 = Tmpstr8
      Call Dispnum()

   End If


Loop