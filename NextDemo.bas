B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=11.2
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: True
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.

End Sub

Sub Globals
	'These global variables will be redeclared each time the activity is created.
	'These variables can only be accessed from this module.
	Private xui As XUI
	Private ListView1 As ListView
	Private dialog As B4XDialog
	Private objConfig As clsConfig
	Private fieldAttr As B4XFloatTextField
	Private fieldEmail As B4XFloatTextField
	Private fieldName As B4XFloatTextField
	Private fieldYear As B4XFloatTextField
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("NextDemoLayout")
	Activity.AddMenuItem("Add", "Add")
	Activity.AddMenuItem("Back", "Back")
	Activity.Title = "Next Demo"
	dialog.Initialize(Activity)	
	objConfig.Initialize
End Sub

Sub Activity_Resume
	sendBack4AppRequest
End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub

Sub Add_Click
	InsertRow
End Sub

Sub Back_Click
	Activity.Finish
End Sub

Sub sendBack4AppRequest()
	Dim Job As HttpJob
	Job.initialize("request", Me)
	Job.Download("https://parseapi.back4app.com/classes/SoccerPlayer")
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-Master-Key", objConfig.masterkey)
	Wait For (Job) JobDone(j As HttpJob)
	If j.Success Then
		Log(j.GetString)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map1 As Map = jparser.Nextobject
			Dim lst1 As List = map1.Get("results")
			ListView1.Clear
			fillTheList(lst1)
		Catch
			Log(LastException)
		End Try
	End If
	j.Release
End Sub

Sub deleteData(i_id As String) As ResumableSub
	Dim Job As HttpJob
	Job.initialize("delete", Me)
	Job.Delete("https://parseapi.back4app.com/classes/SoccerPlayer/" & i_id)
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.apikey)
	ProgressDialogShow("Deleting...")
	Wait For (Job) JobDone(j As HttpJob)
	ProgressDialogHide
	Dim isDeleted As Boolean = False
	If j.Success Then
		Log(j.GetString)
		Msgbox2Async(i_id & " is deleted", "Delete", "Done", "", "", Null, True)
		isDeleted = True
	End If
	j.Release
	Return isDeleted
End Sub

Sub sendData(i_type As String, i_id As String, i_name As String, i_email As String, i_attr As String, i_year As Int) As ResumableSub	
	' {
	'	"name": "A. Wed",
	'	"yearOfBirth": 1997,
	'	"emailContact": "a.wed@email.io",
	'	"attributes": [
	'		"fast",
	'		"good conditioning"
	'	]
	' }	
	Dim arrAttr() As String = Regex.Split("\,", i_attr)
	Dim lstAttr As List
	lstAttr.Initialize2(arrAttr) 
	Dim mapData As Map = CreateMap( _
		"name": i_name, _
		"emailContact": i_email, _ 
		"yearOfBirth": i_year, _ 
		"attributes": lstAttr)
	Dim strdata As String = map2JsonStr(mapData)
	Log("strdata: " & strdata)
	Dim Job As HttpJob
	If i_type.ToLowerCase = "post" Then
		Job.initialize("post", Me)
		Job.PostString("https://parseapi.back4app.com/classes/SoccerPlayer", strdata)
	End If
	If i_type.ToLowerCase = "put" Then
		Job.initialize("put", Me)
		Job.PutString("https://parseapi.back4app.com/classes/SoccerPlayer/" & i_id, strdata)
	End If	
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.apikey)
	Job.GetRequest.SetContentType("application/json")
	If i_type.ToLowerCase = "post" Then
		ProgressDialogShow("Inserting...")
	End If
	If i_type.ToLowerCase = "put" Then
		ProgressDialogShow("Updating...")
	End If	
	Wait For (Job) JobDone(j As HttpJob)
	ProgressDialogHide
	Dim isSent As Boolean 
	If j.Success Then
		Log(j.GetString)		
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map2 As Map = jparser.NextObject
			Dim msg As String = ""
			If i_type = "post" Then
				msg = $"objectId: ${map2.Get("objectId")}${CRLF}createdAt: ${map2.Get("createdAt")}"$
				Msgbox2Async(msg, "POST","Done","","",Null, True)
			End If
			If i_type = "put" Then
				msg = "ObjectId: " & i_id & " Updated at: " & map2.Get("updatedAt")
				Msgbox2Async(msg, "PUT","Done","","",Null, True)
			End If			
			'sendBack4AppRequest
			isSent = True
		Catch
			Log(LastException)
			isSent = False
		End Try
	End If
	j.Release
	Return isSent
End Sub

Sub fillTheList(i_lst As List)
	If i_lst.IsInitialized = False Then
		Return
	End If
	If i_lst.Size = 0 Then
		ListView1.Clear
		Return
	End If
	Dim i As Int = 0
	For i = 0 To i_lst.Size -1
		Dim map1 As Map = i_lst.Get(i)
		Dim lst1 As List = map1.Get("attributes")
		Dim idx As Int = i + 1
		Dim line1 As String = $"${idx}. ${map1.Get("name")}; Born Year: ${map1.Get("yearOfBirth")}"$
		Dim line2 As String = $"Attributes: ${lst1.get(0)}, ${lst1.get(1)}; "$
		ListView1.TwoLinesLayout.Label.TextColor = Colors.Black
		ListView1.TwoLinesLayout.SecondLabel.TextColor = Colors.Black
		ListView1.AddTwoLines2(line1, line2, map1)
	Next
End Sub

Private Sub ListView1_ItemClick (Position As Int, Value As Object)
	
End Sub

Private Sub ListView1_ItemLongClick (Position As Int, Value As Object)
	Dim lstChoosing As List 
	lstChoosing.Initialize2(Array As String("Update", "Delete", "Back"))
	InputListAsync(lstChoosing, "Please choose...", -1, False)
	Wait For InputList_Result (Index As Int)
	Select Index
		Case 0 ' Update
			Dim mapEntry As Map = Value
			UpdateRow(mapEntry)
		Case 1 ' Delete
			Dim mapEntry2 As Map = Value
			deleteData(mapEntry2.Get("objectId"))
		Case Else
			Return
	End Select
End Sub

Sub map2JsonStr(i_map As Map) As String
	If i_map.IsInitialized = False Then Return "{}"
	Dim jgen As JSONGenerator
	Try
		jgen.Initialize(i_map)
		Return jgen.ToString
	Catch
		Log(LastException)
		Return "{}"
	End Try
End Sub

Sub InsertRow()
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, 300dip, 260dip)
	p.LoadLayout("rowDialog")
	dialog.Title = "Insert Dialog"
	dialog.PutAtTop = True 'put the dialog at the top of the screen
	fieldName.Text = "E Sun"
	fieldEmail.Text = "e.sun@email.io"
	fieldAttr.Text = "agile,problem solving"
	fieldYear.Text = 2000
	Wait For (dialog.ShowCustom(p, "OK", "", "CANCEL")) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If IsNumber(fieldYear.Text) = False Then
			Return
		End If
		Wait For (sendData("post", "", fieldName.Text, fieldEmail.Text, fieldAttr.Text, fieldYear.Text)) Complete (ans As Boolean)
		If ans Then
			sendBack4AppRequest
		End If
	End If
End Sub

Sub UpdateRow(i_map As Map)
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, 300dip, 260dip)
	p.LoadLayout("rowDialog")
	dialog.Title = "Update Dialog"
	dialog.PutAtTop = True 'put the dialog at the top of the screen
	fieldName.Text = i_map.Get("name")
	fieldEmail.Text = i_map.Get("emailContact")
	fieldAttr.Text = i_map.Get("attributes")
	fieldYear.Text = i_map.Get("yearOfBirth")
	Wait For (dialog.ShowCustom(p, "OK", "", "CANCEL")) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If IsNumber(fieldYear.Text) = False Then
			Return
		End If
		Wait For (sendData("put", i_map.Get("objectId"), fieldName.Text, fieldEmail.Text, fieldAttr.Text, fieldYear.Text)) Complete (ans As Boolean)
		If ans Then
			sendBack4AppRequest
		End If
	End If
End Sub