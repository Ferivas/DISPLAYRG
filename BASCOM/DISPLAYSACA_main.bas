'Main.bas
'
'                 WATCHING Soluciones Tecnológicas
'                    Fernando Vásquez - 25.06.15
'
' Programa para almacenar los datos que se reciben por el puerto serial a una
' memoria SD
'


$version 0 , 1 , 137
$regfile = "m328pdef.dat"
$crystal = 7372800
$baud = 9600


$hwstack = 80
$swstack = 80
$framesize = 80


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

'TIMER0
Config Timer2 = Timer , Prescale = 64
On Timer2 Int_timer2
Enable Timer2
Start Timer2

' Puerto serial 1
Open "com1:" For Binary As #1
On Urxc At_ser1
Enable Urxc


Enable Interrupts


'*******************************************************************************
'* Archivos incluidos
'*******************************************************************************
$include "DISPLAYSACA_archivos.bas"



'Programa principal

Call Inivar()


Do

   If Sernew = 1 Then                                       'DATOS SERIAL 1
      Reset Sernew
      Print #1 , "SER1=" ; Serproc
      Call Procser()
   End If

   If Inileer = 1 Then
      Reset Inileer

      For Tmpb = 1 To 32
         Print #1 , "BUF_R(" ; Tmpb ; ")=" ; Hexval(bufframr(tmpb)) ; " ; ";
         Print #1 , "BUF_G(" ; Tmpb ; ")=" ; Hexval(bufframg(tmpb))
      Next

   End If

   If Inival = 1 Then
      Reset Inival
      Call Displayval()
   End If

   If Inipeso = 1 Then
      Reset Inipeso
      Set Peso
      Call Displayval()
      Wait 1
      Call Dispunidad()
      Wait 1
      Call Displayval()
      Wait 1
      Call Dispunidad()
      Wait 1
      If Unidad = 1 Then
         Reset Peso
         Unidad = 7
         Call Dispunidad()
         Wait 2
      End If

   End If

   If Initest = 1 Then
      Print #1 , "INI TEST"

      For K = 1 To 32
         Bufframr(k) = 0
         Bufframg(k) = 0
      Next

      Do
         If Sernew = 1 Then                                 'DATOS SERIAL 1
            Reset Sernew
            Print #1 , "SER1=" ; Serproc
            Call Procser()
         End If

         If Newseg = 1 Then
            Reset Newseg
            Incr K
            Print #1 , "Newseg," ; K

            For J = 1 To 32

               If Color = 1 Then
                  Bufframg(j) = &H00
               Else
                  Bufframr(j) = &H00
               End If

            Next

            For J = 1 To 32

               If J = K Then

                  If Color = 1 Then
                     Bufframg(j) = &HFF
                  Else
                     Bufframr(j) = &HFF
                  End If

               End If
            Next

            If K > 32 Then
               Tmpb = K Mod 8
               Print #1 , Tmpb

               For J = 1 To 32

                  If Color = 1 Then
                     Bufframg(j).tmpb = 1
                  Else
                     Bufframr(j).tmpb = 1
                  End If

               Next

            End If

            K = K Mod 48
         End If

      Loop Until Initest = 0

   End If

   If Newseg = 1 And Peso = 0 Then
      Reset Newseg
      Incr Cntrani
      If Esperar = 1 Then

         Select Case Cntrani
            Case 1:
               Unidad = 9
               Incr Color
               Color = Color Mod 2
               Call Dispunidad()
            Case 6:
               For K = 1 To 32
                  Bufframr(k) = 0
                  Bufframg(k) = 0
               Next
         End Select

      Else

         Select Case Cntrani
            Case 1:
               Unidad = 2
               Color = 1
               Call Dispunidad()

            Case 4:
               Unidad = 3
               Color = 0
               Call Dispunidad()

            Case 6:
               For K = 1 To 32
                  Bufframr(k) = 0
                  Bufframg(k) = 0
               Next


         End Select

      End If

      Cntrani = Cntrani Mod 12
   End If

   If Findelay = 1 Then
      Reset Findelay
      Reset Esperar
      Unidad = 8
      Color = 0
      Call Dispunidad()
   End If

Loop