import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_field_validator/form_field_validator.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "-------------------------------------",
      authDomain: "-------------------------------",
      projectId: "-------------------",
      storageBucket: "------------------------",
      messagingSenderId: "-------------------------",
      appId: "--------------------------------------",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Attendance App',
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String userEmail = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text;
      String enteredPassword = passwordController.text;

      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: enteredPassword);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AttendanceMarkingScreen()),
        );

        // Clear the text fields after successful login
        emailController.clear();
        passwordController.clear();
      } catch (e) {
        // Handle login errors
        print('Login error: $e');

        // Show a SnackBar with an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid login credentials. Please try again.'),
            backgroundColor: Colors.red, // Customize the background color
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Center(child: Text(
        "Attendance Management System", style: TextStyle(fontSize: 45))),
    shadowColor: Colors.grey,
    toolbarHeight: 100,
        ),
      body: Center(
        child: Container(
          height: 550,
          width: 500,
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    icon: Icon(Icons.email),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Please enter your email'),
                    EmailValidator(
                        errorText: 'Please enter a valid email address'),
                  ]),
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 16.0),
                // Password Field
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    icon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  obscureText: true,
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 24.0),
                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


  class AttendanceMarkingScreen extends StatefulWidget {
  @override
  _AttendanceMarkingScreenState createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String selectedCourse = ""; // Initialize with an empty course name.
  List<String> courseList = [];
  List<Map<String, dynamic>> studentList = [];

  @override
  void initState() {
    super.initState();
    // Fetch the list of available courses from Firestore.
    fetchCourseList();
    fetchStudentList();
  }

  void fetchCourseList() {
    firestore.collection('courses').get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          // Populate the courseList with course names.
          courseList = querySnapshot.docs
              .map((doc) =>
          (doc.data() as Map<String,
              dynamic>)['course_name'] as String?)
              .where((courseName) => courseName != null)
              .map((courseName) => courseName!)
              .toList();
        });
      }
    });
  }

  void showAddStudentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String studentID = "";
            String studentName = "";

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Student",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Student ID'),
                    onChanged: (value) {
                      studentID = value;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Student Name'),
                    onChanged: (value) {
                      studentName = value;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (studentID.isNotEmpty && studentName.isNotEmpty) {
                        // Add the student to Firestore and close the bottom sheet
                        firestore.collection('students').add({
                          'student_id': studentID,
                          'student_name': studentName,
                        }).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Student added successfully!'),
                            ),
                          );
                          Navigator.pop(context); // Close the bottom sheet
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add student: $error'),
                            ),
                          );
                        });
                      }
                    },
                    child: Text('Add Student'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void fetchStudentList() {
    // Replace 'students' with the name of your Firestore collection for student details.
    firestore.collection('students').get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          // Populate the studentList with student details.
          studentList = querySnapshot.docs
              .map((doc) =>
          {
            'student_id': (doc.data() as Map<String, dynamic>)['student_id'] ??
                '',
            'student_name': (doc.data() as Map<String,
                dynamic>)['student_name'] ?? '',
            'attendance': false,
          })
              .toList();
        });
      }
    });
  }

  // Function to update attendance records in Firestore
  void updateAttendanceRecords() {
    if (selectedCourse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a course before saving attendance records.'),
        ),
      );
      return;
    }
    firestore.collection('attendance').add({
      'course': selectedCourse,
      'date': DateTime.now(),
      'students': studentList
          .where((student) => student['attendance'] == true)
          .map((student) => {
        'student_id': student['student_id'],
        'student_name': student['student_name'],
        'attendance': true,
      })
          .toList(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance records added successfully!'),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add attendance records: $error'),
        ),
      );
    });
  }


  void clearAttendance() {
    setState(() {
      // Reset the attendance status for all students to false
      studentList.forEach((student) {
        student['attendance'] = false;
      });
    });
  }
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    studentList.sort((a, b) => a['student_id'].compareTo(b['student_id']));
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text(
            "Attendance Management System", style: TextStyle(fontSize: 45))),
        shadowColor: Colors.grey,
        toolbarHeight: 100,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment(-0.95, 0),
                  child: DropdownButton<String>(
                    value: selectedCourse.isNotEmpty ? selectedCourse : null,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Select Course"), // Initial value
                      ),
                      ...courseList.map((course) {
                        return DropdownMenuItem<String>(
                          value: course,
                          child: Text(course ?? ""),
                        );
                      }),
                    ],
                    onChanged: (String? course) {
                      setState(() {
                        selectedCourse = course ?? "";
                        fetchStudentList(); // Fetch student details for the selected course.
                      });
                    },
                  ),
                ),
                SizedBox(width: 100.0),
                ElevatedButton(
                  onPressed: () {
                    showAddStudentBottomSheet(context);
                  },
                  child: Text("Add Student"),
                ),
                SizedBox(width: 1100.0),
                Text(
                  "Logged in as: ${FirebaseAuth.instance.currentUser?.email ?? 'Guest'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),


              ],
            ),
            SizedBox(height: 20),
            Text(
              "Attendance Table",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  DataTable(
                    columnSpacing: 150,
                    columns: [
                      DataColumn(label: Text('Student ID')),
                      DataColumn(label: Text('Student Name')),
                      DataColumn(label: Text('Attendance')),
                    ],
                    rows: studentList.map((student) {
                      return DataRow(cells: [
                        DataCell(Text(student['student_id'])),
                        DataCell(Text(student['student_name'])),
                        DataCell(
                          Checkbox(
                            value: student['attendance'],
                            onChanged: (bool? isChecked) {
                              setState(() {
                                student['attendance'] = isChecked ?? false;
                              });
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                updateAttendanceRecords();
                clearAttendance();
              },
              child: Text("Save Attendance"),
            ),
          ],
        ),
      ),
    );
  }
}
