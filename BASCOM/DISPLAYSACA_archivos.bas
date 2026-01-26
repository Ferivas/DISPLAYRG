'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
'*  SD_Archivos.bas                                                        *
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
'*                                                                             *
'*  Variables, Subrutinas y Funciones                                          *
'* WATCHING SOLUCIONES TECNOLOGICAS                                            *
'* 25.06.2015                                                                  *
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

$nocompile


'*******************************************************************************
'Declaracion de subrutinas
'*******************************************************************************
Declare Sub Inivar()
Declare Sub Procser()
Declare Sub Dispnum()
Declare Sub Dispunidad()
Declare Sub Test()
Declare Sub Displayval()


'*******************************************************************************
'Declaracion de variables
'*******************************************************************************
Dim Tmpb As Byte
Dim Tmpb2 As Byte
Dim Tmpb3 As Byte
Dim J As Byte
Dim K As Byte
Dim Cntrtick As Byte
Dim Newseg As Bit
Dim Initest As Bit
Dim Inipeso As Bit
Dim Unidad As Byte
Dim Cntrani As Byte

Dim Cmdtmp As String * 6
Dim Atsnd As String * 200
Dim Cmderr As Byte
Dim Tmpstr8 As String * 16
Dim Tmpstr52 As String * 52
Dim Inileer As Bit
Dim Color As Byte
Dim Esperar As Bit

'Variables Display
Dim Dato8 As Byte
Dim Dato16 As Word
Dim Cntr_col As Byte

Dim Bufframr(32) As Byte                                    ' Buffram para Rojo
Dim Bufframg(32) As Byte                                    ' Buffram para Rojo
Dim Inival As Bit
Dim Ptrm As Byte
Dim Ptrdig As Byte
Dim Peso As Bit

'Variables TIMER0
Dim T0c As Byte
Dim Num_ventana As Byte
Dim Estado As Long
Dim Estado_led As Byte
Dim Iluminar As Bit
Dim Kt2 As Byte
Dim Inidelay As Bit
Dim Cntrdelay As Word
Dim Findelay As Bit

'Variables SERIAL0
Dim Ser_ini As Bit , Sernew As Bit
Dim Numpar As Byte
Dim Cmdsplit(34) As String * 20
Dim Serdata As String * 200 , Serrx As Byte , Serproc As String * 200



'*******************************************************************************
'* END public part                                                             *
'*******************************************************************************


Goto Loaded_arch

'*******************************************************************************
' INTERRUPCIONES
'*******************************************************************************

'*******************************************************************************
' Subrutina interrupcion de puerto serial 1
'*******************************************************************************
At_ser1:
   Serrx = Udr

   Select Case Serrx
      Case "*":
         Ser_ini = 1
         Serdata = ""

      Case 13:
         If Ser_ini = 1 Then
            Ser_ini = 0
            Serdata = Serdata + Chr(0)
            Serproc = Serdata
            Sernew = 1
            Enable Timer0
         End If

      Case Is > 31
         If Ser_ini = 1 Then
            Serdata = Serdata + Chr(serrx)
         End If

   End Select

Return


Return

'*******************************************************************************



'*******************************************************************************
' TIMER0
'*******************************************************************************
Int_timer0:
   Timer0 = &HB8
   Incr T0c
   T0c = T0c Mod 8
   If T0c = 0 Then
      Num_ventana = Num_ventana Mod 32
      Estado = Lookup(estado_led , Tabla_estado)
      Iluminar = Estado.num_ventana
      'Toggle Iluminar
      Led1 = Iluminar
      Incr Num_ventana
   End If

   Incr Cntrtick
   Cntrtick = Cntrtick Mod 50
   If Cntrtick = 0 Then
      Set Newseg

   End If

   If Inidelay = 1 Then
      Incr Cntrdelay
      Cntrdelay = Cntrdelay Mod 3200
      If Cntrdelay = 0 Then
         Print #1 , "Findelay"
         Reset Inidelay
         Set Findelay
      End If
   End If

Return


'*******************************************************************************
' TIMER0
'*******************************************************************************
Int_timer2:
   Timer2 = &H88                                            '960
   Toggle Pinbug

   Set Oenac
   Set Oenag
   Set Oenar

   Incr Cntr_col
   Dato16 = Lookup(cntr_col , Tbl_col)
   Shiftout Datos , Sck , Dato16 , 1

   Set Lenac
   Reset Lenac
   Reset Oenac

   Dato8 = Bufframr(cntr_col)
   Shiftout Datos , Sck , Dato8 , 3
   Dato8 = Bufframg(cntr_col)
   Shiftout Datos , Sck , Dato8 , 3
   Set Lenar
   Reset Lenar
   Reset Oenar

   Dato8 = Bufframr(cntr_col + 16)
   Shiftout Datos , Sck , Dato8 , 3
   Dato8 = Bufframg(cntr_col + 16)
   Shiftout Datos , Sck , Dato8 , 3
   Set Lenag
   Reset Lenag
   Reset Oenag


   Cntr_col = Cntr_col Mod 16

Return




'*******************************************************************************
' SUBRUTINAS
'*******************************************************************************

'*******************************************************************************
' Inicialización de variables
'*******************************************************************************
Sub Inivar()
Reset Led1
Print #1 , "************ DRIVER AUDIO ************"
Print #1 , Version(1)
Print #1 , Version(2)
Print #1 , Version(3)
Estado_led = 1
Reset Initest
Color = 1
Reset Sernew
Reset Peso
'Bufframr(1) = &H0E
'Bufframg(2) = &H0E
'Bufframr(3) = &H0E
'Bufframg(3) = &H0E

End Sub

' Subrutina para mostar valor de digito centrado en mitad del display
Sub Dispnum()
      Tmpb = Len(tmpstr52)
      If Tmpb > 5 Then
         Tmpb = 5
      End If

      For K = 1 To 32
         Bufframr(k) = 0
         Bufframg(k) = 0
      Next
      Tmpb2 = Tmpb - 1
      Ptrm = Lookup(tmpb2 , Tbl_pos)
      Print #1 , "PTRM=" ; Ptrm
      For J = 1 To Tmpb
         Tmpstr8 = Mid(tmpstr52 , J , 1)
         If Tmpstr8 <> "." Then
            Tmpb2 = Val(tmpstr8)
            Ptrdig = Tmpb2 * 5
            Print #1 , "Ptrdig=" ; Ptrdig
            For K = 1 To 5
               Incr Ptrm
               Tmpb3 = Lookup(ptrdig , Tbl_char)
               Incr Ptrdig
               If Color = 0 Then
                  Bufframr(ptrm) = Tmpb3
               End If

               If Color = 1 Then
                  Bufframg(ptrm) = Tmpb3
               End If

               If Color = 2 Then
                  Bufframr(ptrm) = Tmpb3
                  Bufframg(ptrm) = Tmpb3
               End If


            Next
            Incr Ptrm
            If Color = 0 Then
               Bufframr(ptrm) = 0                           ' Espacio
            End If
            If Color = 1 Then
               Bufframg(ptrm) = 0
            End If

            If Color = 2 Then
               Bufframr(ptrm) = 0
               Bufframg(ptrm) = 0
            End If


         Else
           Incr Ptrm
            If Color = 0 Then
               Bufframr(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &H00
            End If
            If Color = 1 Then
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframg(ptrm) = &H00

            End If

            If Color = 2 Then
               Bufframr(ptrm) = &B11000000
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &B11000000
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &H00
               Bufframg(ptrm) = &H00
            End If

         End If

      Next



End Sub


Sub Dispunidad()

   Cntrtick = 1

   For K = 1 To 32
      Bufframr(k) = 0
      Bufframg(k) = 0
   Next

   For K = 1 To 32
      If Unidad = 0 Then
         Tmpb = Lookup(k , Tbl_kilos)
      End If

      If Unidad = 1 Then
         Tmpb = Lookup(k , Tbl_libras)
      End If

      If Unidad = 2 Then
         Tmpb = Lookup(k , Tbl_virtual)
      End If

      If Unidad = 3 Then
         Tmpb = Lookup(k , Tbl_gym)
      End If

      If Unidad = 4 Then
         Tmpb = Lookup(k , Tbl_suba)
      End If

      If Unidad = 5 Then
         Tmpb = Lookup(k , Tbl_por)
      End If

      If Unidad = 6 Then
         Tmpb = Lookup(k , Tbl_favor)
      End If

      If Unidad = 7 Then
         Tmpb = Lookup(k , Tbl_gracias)
      End If

      If Unidad = 8 Then
         Tmpb = Lookup(k , Tbl_error)
      End If

      If Unidad = 9 Then
         Tmpb = Lookup(k , Tbl_espere)
      End If

      If Unidad = 10 Then
         Tmpb = Lookup(k , Tbl_ok)
      End If

      If Unidad = 11 Then
         Tmpb = Lookup(k , Tbl_tara)
      End If

      If Unidad = 12 Then
         Tmpb = Lookup(k , Tbl_patron)
      End If

      If Color = 0 Then
         Bufframr(k) = Tmpb
      End If

      If Color = 1 Then
         Bufframg(k) = Tmpb
      End If

      If Color = 2 Then
         Bufframr(k) = Tmpb
         Bufframg(k) = Tmpb
      End If

   Next

   Cntrtick = 1
End Sub


Sub Displayval()
      Cntrtick = 1
      Tmpb = Len(tmpstr52)

      If Tmpb > 5 Then
         Tmpb = 5
      End If

      For K = 1 To 32
         Bufframr(k) = 0
         Bufframg(k) = 0
      Next
      Tmpb2 = Tmpb - 1
      Ptrm = Lookup(tmpb2 , Tbl_pos)
      Print #1 , "PTRM=" ; Ptrm
      For J = 1 To Tmpb
         Tmpstr8 = Mid(tmpstr52 , J , 1)
         If Tmpstr8 <> "." Then
            Tmpb2 = Val(tmpstr8)
            Ptrdig = Tmpb2 * 5
            Print #1 , "Ptrdig=" ; Ptrdig
            For K = 1 To 5
               Incr Ptrm
               Tmpb3 = Lookup(ptrdig , Tbl_char)
               Incr Ptrdig
               If Color = 0 Then
                  Bufframr(ptrm) = Tmpb3
               End If

               If Color = 1 Then
                  Bufframg(ptrm) = Tmpb3
               End If

               If Color = 2 Then
                  Bufframr(ptrm) = Tmpb3
                  Bufframg(ptrm) = Tmpb3
               End If
            Next
            Incr Ptrm
            If Color = 0 Then
               Bufframr(ptrm) = 0                           ' Espacio
            End If
            If Color = 1 Then
               Bufframg(ptrm) = 0
            End If

            If Color = 2 Then
               Bufframr(ptrm) = 0
               Bufframg(ptrm) = 0
            End If


         Else
           Incr Ptrm
            If Color = 0 Then
               Bufframr(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &H00
            End If
            If Color = 1 Then
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframg(ptrm) = &H00

            End If

            If Color = 2 Then
               Bufframr(ptrm) = &B11000000
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &B11000000
               Bufframg(ptrm) = &B11000000
               Incr Ptrm
               Bufframr(ptrm) = &H00
               Bufframg(ptrm) = &H00
            End If

         End If

      Next



End Sub



Sub Test()
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

End Sub

'*******************************************************************************
' Procesamiento de comandos
'*******************************************************************************
Sub Procser()
   Print #1 , "$" ; Serproc
   Tmpstr52 = Mid(serproc , 1 , 6)
   Numpar = Split(serproc , Cmdsplit(1) , ",")
   If Numpar > 0 Then
      For Tmpb = 1 To Numpar
         Print #1 , Tmpb ; ":" ; Cmdsplit(tmpb)
      Next
   End If
   Serproc = ""

   If Len(cmdsplit(1)) = 6 Then
      Cmdtmp = Cmdsplit(1)
      Cmdtmp = Ucase(cmdtmp)
      Cmderr = 255
      Select Case Cmdtmp
         Case "LEEVFW"
            Cmderr = 0
            Atsnd = "Version FW: Fecha <"
            Tmpstr52 = Version(1)
            Atsnd = Atsnd + Tmpstr52 + ">, Archivo <"
            Tmpstr52 = Version(3)
            Atsnd = Atsnd + Tmpstr52 + ">"


         Case "SETLED"
            If Numpar = 2 Then
               Tmpb = Val(cmdsplit(2))
               If Tmpb < 17 Then
                  Cmderr = 0
                  Atsnd = "Se configura setled a " + Str(tmpb)
                  Estado_led = Tmpb

               Else
                  Cmderr = 5
               End If

            Else
               Cmderr = 4

            End If


         Case "SETBUR"
            If Numpar = 3 Then
               Tmpb = Val(cmdsplit(2))
               If Tmpb < 33 Then
                  Cmderr = 0
                  Tmpb2 = Hexval(cmdsplit(3))
                  Atsnd = "Se configura buff_R(" + Str(tmpb) + ")=" + Hex(tmpb2)
                  Bufframr(tmpb) = Tmpb2
               Else
                  Cmderr = 5
               End If
            Else
               Cmderr = 4

            End If

         Case "SETBUG"
            If Numpar = 3 Then
               Tmpb = Val(cmdsplit(2))
               If Tmpb < 33 Then
                  Cmderr = 0
                  Tmpb2 = Hexval(cmdsplit(3))
                  Atsnd = "Se configura buff_G(" + Str(tmpb) + ")=" + Hex(tmpb2)
                  Bufframg(tmpb) = Tmpb2
               Else
                  Cmderr = 5
               End If
            Else
               Cmderr = 4

            End If

         Case "LEEBUF"
            Cmderr = 0
            Atsnd = "Leedatos buf"
            Set Inileer

         Case "SETVAL"                                      ' Muestra valor en display
            If Numpar = 3 Then
               Cmderr = 0
               Tmpstr52 = Cmdsplit(2)
               Color = Val(cmdsplit(3))
               If Color < 3 Then
                  Atsnd = "Setear texto <" + Tmpstr52 + ">"
                  Set Inival
               Else
                  Cmderr = 6
               End If
            Else
               Cmderr = 5
            End If

         Case "SETPES"                                      ' Muestra valor de peso
            If Numpar = 4 Then
               Cmderr = 0
               Tmpstr52 = Cmdsplit(2)
               Color = Val(cmdsplit(3))
               If Color < 3 Then
                  Unidad = Val(cmdsplit(4))
                  If Unidad < 2 Then
                     Atsnd = "Setear texto <" + Tmpstr52 + ">"
                     Reset Esperar
                     Reset Inidelay
                     Cntrdelay = 0
                     Set Inipeso
                  Else
                     Cmderr = 4
                  End If
               Else
                  Cmderr = 6
               End If
            Else
               Cmderr = 5
            End If

         Case "INIPES"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 4
                  Call Dispunidad()
                  Wait 1
                  Unidad = 5
                  Call Dispunidad()
                  Wait 1
                  Unidad = 6
                  Call Dispunidad()
                  Wait 1
                  Set Esperar
                  Cntrdelay = 0
                  Set Inidelay
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "ERRPES"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 8
                  Call Dispunidad()
                  Wait 1
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "TARAOK"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 11
                  Call Dispunidad()
                  Wait 1
                  Unidad = 10
                  Call Dispunidad()
                  Wait 1
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "TARAER"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 11
                  Call Dispunidad()
                  Wait 1
                  Unidad = 8
                  Call Dispunidad()
                  Wait 1
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "PTRNOK"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 12
                  Call Dispunidad()
                  Wait 1
                  Unidad = 10
                  Call Dispunidad()
                  Wait 1
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "PTRNER"
            If Numpar = 2 Then
               Cmderr = 0
               Color = Val(cmdsplit(2))
               If Color < 3 Then
                  Reset Esperar
                  Reset Inidelay
                  Cntrdelay = 0
                  Unidad = 12
                  Call Dispunidad()
                  Wait 1
                  Unidad = 8
                  Call Dispunidad()
                  Wait 1
               Else
                  Cmderr = 4
               End If
            Else
               Cmderr = 6
            End If

         Case "SETCER"
            Cmderr = 0
            Atsnd = "Encera buffers"
            For K = 1 To 32
               Bufframr(k) = 0
               Bufframg(k) = 0
            Next

         Case "SETTST"
            If Numpar = 2 Then
               Color = Val(cmdsplit(2))
               If Color < 2 Then
                  Cmderr = 0
                  Atsnd = "Ini TEST"
                  Set Initest
               Else
                  Cmderr = 6
               End If
            Else
               Cmderr = 5
            End If

         Case "RSTTST"
            Cmderr = 0
            Atsnd = "Fin TEST"
            Reset Initest

         Case "SETKIL"
            If Numpar = 2 Then
               Tmpb = Val(cmdsplit(2))
               If Tmpb < 3 Then
                  Color = Tmpb
                  Cmderr = 0
                  Atsnd = "Setea Kilos"
                  For K = 1 To 32
                     Bufframr(k) = 0
                     Bufframg(k) = 0
                  Next

                  For K = 1 To 32
                     Tmpb = Lookup(k , Tbl_kilos)
                     If Color = 0 Then
                        Bufframr(k) = Tmpb
                     End If

                     If Color = 1 Then
                        Bufframg(k) = Tmpb
                     End If

                     If Color = 2 Then
                        Bufframr(k) = Tmpb
                        Bufframg(k) = Tmpb
                     End If

                  Next
               Else
                  Cmderr = 6
               End If
            Else
               Cmderr = 5

            End If

         Case "SETLIB"
            If Numpar = 2 Then
               Tmpb = Val(cmdsplit(2))
               If Tmpb < 3 Then
                  Color = Tmpb
                  Cmderr = 0
                  Atsnd = "Setea Kilos"
                  For K = 1 To 32
                     Bufframr(k) = 0
                     Bufframg(k) = 0
                  Next

                  For K = 1 To 32
                     Tmpb = Lookup(k , Tbl_libras)
                     If Color = 0 Then
                        Bufframr(k) = Tmpb
                     End If

                     If Color = 1 Then
                        Bufframg(k) = Tmpb
                     End If

                     If Color = 2 Then
                        Bufframr(k) = Tmpb
                        Bufframg(k) = Tmpb
                     End If

                  Next
               Else
                  Cmderr = 6
               End If
            Else
               Cmderr = 5

            End If

         Case Else
            Cmderr = 1

      End Select

   Else
        Cmderr = 2
   End If

   Print #1 , Atsnd

   If Cmderr > 0 Then
      Atsnd = Lookupstr(cmderr , Tbl_err)
   End If

   Print #1 , Atsnd
   Atsnd = ""

End Sub



'*******************************************************************************
'TABLA DE DATOS
'*******************************************************************************
Tbl_col:
Data &B0000000000000000%                                    'Dummy data
Data &B0000000000000001%                                    ' Col1
Data &B0000000000000010%                                    ' Col2
Data &B0000000000000100%                                    ' Col3
Data &B0000000000001000%                                    ' Col4
Data &B0000000000010000%                                    ' Col5
Data &B0000000000100000%                                    ' Col6
Data &B0000000001000000%                                    ' Col7
Data &B0000000010000000%                                    ' Col8
Data &B0000000100000000%                                    ' Col9
Data &B0000001000000000%                                    ' Col10
Data &B0000010000000000%                                    ' Col11
Data &B0000100000000000%                                    ' Col12
Data &B0001000000000000%                                    ' Col13
Data &B0010000000000000%                                    ' Col14
Data &B0100000000000000%                                    ' Col15
Data &B1000000000000000%                                    ' Col16



Tbl_pos:
Data 12
Data 12
Data 9
Data 6
Data 3
Data 0


Tbl_kilos:
Data &H00                                                   'dUMMY DATA
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &B11111111,                                            ' #########
Data &B00100000,                                            '   #
Data &B00110000,                                            '   ##
Data &B01001000,                                            '  #  #
Data &B10000100,                                            ' #    #
Data &H00,
Data &B11111101 ,                                           ' ######  #
Data &H00,
Data &B11111111                                             ' #########
Data &H00,
Data &B01111000 ,                                           '  ####
Data &B10000100 ,                                           ' #    #
Data &B10000100 ,                                           ' #    #
Data &B10000100 ,                                           ' #    #
Data &B01111000 ,                                           '  ####
Data &H00,
Data &B10011000 ,                                           ' #  ##
Data &B10010100 ,                                           ' #  # #
Data &B10100100 ,                                           ' # #  #
Data &B01100100 ,                                           '  ##  #
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,

Tbl_libras:
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &B11111111                                             ' #########
Data &H00,
Data &B11111101 ,                                           ' ######  #
Data &H00,
Data &B11111111 ,                                           ' #########
Data &B10000100 ,                                           ' #    #
Data &B10000100 ,                                           ' #    #
Data &B01111000 ,                                           '  ####
Data &H00,
Data &B11111100 ,                                           ' ######
Data &B00001000 ,                                           '     #
Data &B00000100 ,                                           '      #
Data &B00000100 ,                                           '      #
Data &H00,
Data &B01100000 ,                                           '  ##
Data &B10010100 ,                                           ' #  # #
Data &B10010100 ,                                           ' #  # #
Data &B10010100 ,                                           ' #  # #
Data &B11111000 ,                                           ' #####
Data &H00,
Data &B10011000 ,                                           ' #  ##
Data &B10010100 ,                                           ' #  # #
Data &B10100100 ,                                           ' # #  #
Data &B01100100 ,                                           '  ##  #
Data &H00,
Data &H00,
Data &H00,
Data &H00,


Tbl_virtual:
Data &H00,
Data &B00011111,                                            '      ###
Data &B00100000,                                            '   ##
Data &B11000000,                                            ' ##
Data &B00100000,                                            '   ##
Data &B00011111,                                            '       ##
Data &H00,
Data &B11111111,                                            ' ########
Data &H00,
Data &B11111111,                                            ' ########
Data &B00100001,                                            '   #    #
Data &B01100001,                                            '  ##    #
Data &B10011110,                                            ' #  ####
Data &H00,
Data &B00000001,                                            '        #
Data &B11111111,                                            ' ########
Data &B00000001,                                            '        #
Data &H00,
Data &B01111111,                                            '  #######
Data &B10000000,                                            ' #
Data &B10000000,                                            ' #
Data &B01111111,                                            '  #######
Data &H00,
Data &B11111100,                                            ' ######
Data &B00100010,                                            '   #   #
Data &B00100001,                                            '   #    #
Data &B00100010,                                            '   #   #
Data &B11111100,                                            ' ######
Data &H00,
Data &B11111111,                                            ' ########
Data &B10000000,                                            ' #
Data &B10000000,                                            ' #
Data &B10000000,                                            ' #

Tbl_gym:
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &H00,
Data &B00111100,                                            '   ####
Data &B01000010,                                            '  #    #
Data &B10000001,                                            ' #      #
Data &B10010001,                                            ' #  #   #
Data &B01010010,                                            '  # #  #
Data &B00110100,                                            '   ## #
Data &H00,
Data &H00,
Data &B00000001,                                            '        #
Data &B00000110,                                            '      ##
Data &B00001000,                                            '     #
Data &B11110000,                                            ' ####
Data &B00001000,                                            '     #
Data &B00000110,                                            '      ##
Data &B00000001,                                            '        #
Data &H00,
Data &H00,
Data &B11111111,                                            ' ########
Data &B00000110,                                            '      ##
Data &B00111000,                                            '   ###
Data &B11000000,                                            ' ##
Data &B00111000,                                            '   ###
Data &B00000110,                                            '      ##
Data &B11111111,                                            ' ########
Data &H00,
Data &H00,
Data &H00,
Data &H00,



Tbl_char:
        '@1 '0' (5 pixels wide)
Data &B01111110,                                            ' ######
Data &B10000001,                                            '#      #
Data &B10000001,                                            '#      #
Data &B10000001,                                            '#      #
Data &B01111110,                                            ' ######

        '@6 '1' (5 pixels wide)
Data &B10000010,                                            '#     #
Data &B10000010,                                            '#     #
Data &B11111111,                                            '########
Data &B10000000,                                            '#
Data &B10000000,                                            '#

        '@11 '2' (5 pixels wide)
Data &B11000010,                                            '##    #
Data &B10100001,                                            '# #    #
Data &B10010001,                                            '#  #   #
Data &B10001001,                                            '#   #  #
Data &B10000110,                                            '#    ##

        '@16 '3' (5 pixels wide)
Data &B01000010,                                            ' #    #
Data &B10000001,                                            '#      #
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B01110110,                                            ' ### ##

        '@21 '4' (6 pixels wide)
Data &B00011000,                                            '   ##
Data &B00010100,                                            '   # #
Data &B00010010,                                            '   #  #
Data &B11111111,                                            '########
Data &B00010000,                                            '  #

        '@27 '5' (5 pixels wide)
Data &B01001111,                                            ' #  ####
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B01110001,                                            ' ###   #

        '@32 '6' (5 pixels wide)
Data &B01111100,                                            ' #####
Data &B10001010,                                            '#   # #
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B01110000,                                            ' ###

        '@37 '7' (5 pixels wide)
Data &B00000001,                                            '       #
Data &B11000001,                                            '##     #
Data &B00110001,                                            '  ##   #
Data &B00001101,                                            '    ## #
Data &B00000011,                                            '      ##

        '@42 '8' (5 pixels wide)
Data &B01110110,                                            ' ### ##
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B10001001,                                            '#   #  #
Data &B01110110,                                            ' ### ##

        '@47 '9' (5 pixels wide)
Data &B00001110,                                            '    ###
Data &B10010001,                                            '#  #   #
Data &B10010001,                                            '#  #   #
Data &B01010001,                                            ' # #   #
Data &B00111110,                                            '  #####

' Espacio
Data &B00000000,
Data &B00000000,
Data &B00000000,
Data &B00000000,
Data &B00000000,

' Punto
Data &B11000000,                                            '##

Tbl_suba:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B01000110,                                            '  #   ##
Data &B10001001,                                            ' #   #  #
Data &B10001001,                                            ' #   #  #
Data &B10010001,                                            ' #  #   #
Data &B10010001,                                            ' #  #   #
Data &B01100010,                                            '  ##   #
Data &B00000000,                                            '
Data &B01111100,                                            '  #####
Data &B10000000,                                            ' #
Data &B10000000,                                            ' #
Data &B01000000,                                            '  #
Data &B11111100,                                            ' ######
Data &B00000000,                                            '
Data &B11111111,                                            ' ########
Data &B01001000,                                            '  #  #
Data &B10000100,                                            ' #    #
Data &B10000100,                                            ' #    #
Data &B01111000,                                            '  ####
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '                                           '

Tbl_por:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B11111111,                                            ' ########
Data &B00010010,                                            '    #  #
Data &B00100001,                                            '   #    #
Data &B00100001,                                            '   #    #
Data &B00011110,                                            '    ####
Data &B00000000,                                            '
Data &B00011110,                                            '    ####
Data &B00100001,                                            '   #    #
Data &B00100001,                                            '   #    #
Data &B00100001,                                            '   #    #
Data &B00011110,                                            '    ####
Data &B00000000,                                            '
Data &B00111111,                                            '   ######
Data &B00000010,                                            '       #
Data &B00000001,                                            '        #
Data &B00000001,                                            '        #
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '

Tbl_favor:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000100,                                            '      #
Data &B11111110,                                            ' #######
Data &B00000101,                                            '      # #
Data &B00000101,                                            '      # #
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B00001100,                                            '     ##
Data &B00110000,                                            '   ##
Data &B11000000,                                            ' ##
Data &B00110000,                                            '   ##
Data &B00001100,                                            '     ##
Data &B00000000,                                            '
Data &B01111000,                                            '  ####
Data &B10000100,                                            ' #    #
Data &B10000100,                                            ' #    #
Data &B01111000,                                            '  ####
Data &B00000000,                                            '
Data &B11111100,                                            ' ######
Data &B00001000,                                            '     #
Data &B00000100,                                            '      #
Data &B00000100,                                            '      #
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '

Tbl_gracias:
Data &B00000000,                                            '
Data &B00111100,                                            '   ####
Data &B01000010,                                            '  #    #
Data &B10000001,                                            ' #      #
Data &B10010001,                                            ' #  #   #
Data &B01010010,                                            '  # #  #
Data &B00110100,                                            '   ## #
Data &B00000000,                                            '
Data &B11111100,                                            ' ######
Data &B00001000,                                            '     #
Data &B00000100,                                            '      #
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B01111000,                                            '  ####
Data &B10000100,                                            ' #    #
Data &B10000100,                                            ' #    #
Data &B01001000,                                            '  #  #
Data &B00000000,                                            '
Data &B11111101,                                            ' ###### #
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B01001000,                                            '  #  #
Data &B10010100,                                            ' #  # #
Data &B10100100,                                            ' # #  #
Data &B01001000,                                            '  #  #

Tbl_error:
Data &B00000000,
Data &B00000000,
Data &B11111111,                                            ' ########
Data &B10001001,                                            ' #   #  #
Data &B10001001,                                            ' #   #  #
Data &B10001001,                                            ' #   #  #
Data &B10001001,                                            ' #   #  #
Data &B00000000,
Data &B11111111,                                            ' ########
Data &B00001001,                                            '     #  #
Data &B00011001,                                            '    ##  #
Data &B01101001,                                            '  ## #  #
Data &B10000110,                                            ' #    ##
Data &B00000000,
Data &B11111111,                                            ' ########
Data &B00001001,                                            '     #  #
Data &B00011001,                                            '    ##  #
Data &B01101001,                                            '  ## #  #
Data &B10000110,                                            ' #    ##
Data &B00000000,
Data &B00111100,                                            '   ####
Data &B01000010,                                            '  #    #
Data &B10000001,                                            ' #      #
Data &B10000001,                                            ' #      #
Data &B01000010,                                            '  #    #
Data &B00111100,                                            '   ####
Data &B00000000,
Data &B11111111,                                            ' ########
Data &B00001001,                                            '     #  #
Data &B00011001,                                            '    ##  #
Data &B01101001,                                            '  ## #  #
Data &B10000110,                                            ' #    ##
Data &B00000000,                                            '

Tbl_ok:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00111100,                                            '   ####
Data &B01000010,                                            '  #    #
Data &B10000001,                                            ' #      #
Data &B10000001,                                            ' #      #
Data &B10000001,                                            ' #      #
Data &B01000010,                                            '  #    #
Data &B00111100,                                            '   ####
Data &B00000000,                                            '
Data &B11111111,                                            ' ########
Data &B00010000,                                            '    #
Data &B00001000,                                            '     #
Data &B00011100,                                            '    ###
Data &B01100010,                                            '  ##   #
Data &B10000001,                                            ' #      #
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '

Tbl_espere:
Data &B00000000,                                            '
Data &B01111111,                                            '  #######
Data &B01001001,                                            '  #  #  #
Data &B01001001,                                            '  #  #  #
Data &B01001001,                                            '  #  #  #
Data &B00000000,                                            '
Data &B00100100,                                            '   #  #
Data &B01001010,                                            '  #  # #
Data &B01001010,                                            '  #  # #
Data &B01010010,                                            '  # #  #
Data &B00100100,                                            '   #  #
Data &B00000000,                                            '
Data &B11111111,                                            ' ########
Data &B00010010,                                            '    #  #
Data &B00100001,                                            '   #    #
Data &B00100001,                                            '   #    #
Data &B00011110,                                            '    ####
Data &B00000000,                                            '
Data &B00111100,                                            '   ####
Data &B01001010,                                            '  #  # #
Data &B01001010,                                            '  #  # #
Data &B01001010,                                            '  #  # #
Data &B00101100,                                            '   # ##
Data &B00000000,                                            '
Data &B01111110,                                            '  ######
Data &B00000100,                                            '      #
Data &B00000010,                                            '       #
Data &B00000000,                                            '
Data &B00111100,                                            '   ####
Data &B01001010,                                            '  #  # #
Data &B01001010,                                            '  #  # #
Data &B01001010,                                            '  #  # #
Data &B00101100,                                            '   # ##

Tbl_tara:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000001,                                            '        #
Data &B00000001,                                            '        #
Data &B11111111,                                            ' ########
Data &B00000001,                                            '        #
Data &B00000001,                                            '        #
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B11111100,                                            ' ######
Data &B00001000,                                            '     #
Data &B00000100,                                            '      #
Data &B00000100,                                            '      #
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B00000000,                                            '

Tbl_patron:
Data &B00000000,                                            '
Data &B00000000,                                            '
Data &B11111111,                                            ' ########
Data &B00010001,                                            '    #   #
Data &B00010001,                                            '    #   #
Data &B00001110,                                            '     ###
Data &B00000000,                                            '
Data &B01101000,                                            '  ## #
Data &B10010100,                                            ' #  # #
Data &B10010100,                                            ' #  # #
Data &B01010100,                                            '  # # #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '
Data &B00000100,                                            '      #
Data &B11111111,                                            ' ########
Data &B10000100,                                            ' #    #
Data &B00000000,                                            '
Data &B11111100,                                            ' ######
Data &B00001000,                                            '     #
Data &B00000100,                                            '      #
Data &B00000000,                                            '
Data &B01111000,                                            '  ####
Data &B10000100,                                            ' #    #
Data &B10000100,                                            ' #    #
Data &B10000100,                                            ' #    #
Data &B01111000,                                            '  ####
Data &B00000000,                                            '
Data &B11111100,                                            ' ######
Data &B00000100,                                            '      #
Data &B00000100,                                            '      #
Data &B00000100,                                            '      #
Data &B11111000,                                            ' #####
Data &B00000000,                                            '



Tbl_err:

Data "OK"                                                   '0
Data "Comando no reconocido"                                '1
Data "Longitud comando no valida"                           '2
Data "Numero de usuario no valido"                          '3
Data "Numero de parametros invalido"                        '4
Data "Error longitud parametro 1"                           '5
Data "Error longitud parametro 2"                           '6
Data "Parametro no valido"                                  '7
Data "ERROR8"                                               '8
Data "ERROR SD. Intente de nuevo"                           '9

Tabla_estado:
Data &B00000000000000000000000000000000&                    'Estado 0
Data &B00000000000000000000000000000011&                    'Estado 1
Data &B00000000000000000000000000110011&                    'Estado 2
Data &B00000000000000000000001100110011&                    'Estado 3
Data &B00000000000000000011001100110011&                    'Estado 4
Data &B00000000000000110011001100110011&                    'Estado 5
Data &B00000000000011001100000000110011&                    'Estado 6
Data &B00001111111111110000111111111111&                    'Estado 7
Data &B01010101010101010101010101010101&                    'Estado 8
Data &B00110011001100110011001100110011&                    'Estado 9
Data &B01110111011101110111011101110111&                    'Estado 10
Data &B11111111111111000000000000001100&                    'Estado 11
Data &B11111111111111000000000011001100&                    'Estado 12
Data &B11111111111111000000110011001100&                    'Estado 13
Data &B11111111111111001100110011001100&                    'Estado 14
Data &B11111111111111000000000000001100&                    'Estado 15
Data &B11111111111111111111111111110000&                    'Estado 16



Loaded_arch: