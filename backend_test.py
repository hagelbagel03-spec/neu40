#!/usr/bin/env python3
"""
Comprehensive Backend API Testing for German Stadtwache App
Tests all backend APIs systematically with German test data
"""

import requests
import json
import sys
from datetime import datetime
import uuid

class StadtwacheAPITester:
    def __init__(self):
        # Use the frontend's configured backend URL
        self.base_url = "https://deutsch-bearbeiter.preview.emergentagent.com/api"
        self.session = requests.Session()
        self.auth_token = None
        self.current_user = None
        self.test_results = []
        
        # German test data
        self.demo_user = {
            "email": "demo@stadtwache.de",
            "password": "demo123"
        }
        
        self.test_users = [
            {
                "email": "mueller@stadtwache.de",
                "username": "Hans Müller",
                "password": "sicher123",
                "role": "police",
                "badge_number": "SW001",
                "department": "Streifendienst",
                "phone": "+49 30 12345678",
                "service_number": "12345",
                "rank": "Hauptwachtmeister"
            },
            {
                "email": "schmidt@stadtwache.de", 
                "username": "Anna Schmidt",
                "password": "geheim456",
                "role": "police",
                "badge_number": "SW002",
                "department": "Ermittlung",
                "phone": "+49 30 87654321",
                "service_number": "67890",
                "rank": "Kommissarin"
            }
        ]
        
        self.test_incidents = [
            {
                "title": "Ruhestörung in der Hauptstraße",
                "description": "Laute Musik aus Wohnung im 3. Stock. Nachbarn beschweren sich über nächtliche Lärmbelästigung.",
                "priority": "medium",
                "location": {"lat": 52.5200, "lng": 13.4050},
                "address": "Hauptstraße 15, 10115 Berlin"
            },
            {
                "title": "Verdächtiges Fahrzeug am Bahnhof",
                "description": "Schwarzer BMW ohne Kennzeichen parkt seit 2 Stunden vor dem Hauptbahnhof. Fahrer verhält sich auffällig.",
                "priority": "high", 
                "location": {"lat": 52.5251, "lng": 13.3694},
                "address": "Hauptbahnhof Berlin, Europaplatz 1, 10557 Berlin"
            },
            {
                "title": "Fahrraddiebstahl gemeldet",
                "description": "Hochwertiges Mountainbike wurde aus verschlossenem Fahrradkeller entwendet. Schloss wurde aufgebrochen.",
                "priority": "low",
                "location": {"lat": 52.5170, "lng": 13.3888},
                "address": "Friedrichstraße 95, 10117 Berlin"
            }
        ]
        
        self.test_messages = [
            {
                "content": "Guten Morgen Team! Schichtbeginn um 06:00 Uhr.",
                "channel": "general"
            },
            {
                "content": "Achtung: Verdächtiges Fahrzeug am Bahnhof gemeldet. Alle verfügbaren Einheiten bitte melden.",
                "channel": "emergency"
            },
            {
                "content": "Vorfall Hauptstraße abgeschlossen. Verwarnung erteilt.",
                "channel": "incidents"
            }
        ]
        
        self.test_reports = [
            {
                "title": "Schichtbericht Nachtdienst 15.01.2025",
                "content": "Ruhige Nacht mit 3 Einsätzen:\n1. Ruhestörung Hauptstraße - Verwarnung erteilt\n2. Fahrzeugkontrolle Bahnhof - Verdacht nicht bestätigt\n3. Fahrraddiebstahl - Anzeige aufgenommen\n\nBesondere Vorkommnisse: Keine\nWetter: Klar, -2°C",
                "shift_date": "2025-01-15"
            },
            {
                "title": "Wochenbericht KW 3/2025",
                "content": "Zusammenfassung der Woche:\n- 15 Einsätze bearbeitet\n- 3 Anzeigen aufgenommen\n- 2 Verwarnungen erteilt\n- 1 Festnahme\n\nSchwerpunkte: Fahrraddiebstähle in der Innenstadt nehmen zu.",
                "shift_date": "2025-01-20"
            }
        ]

    def log_result(self, test_name, success, details="", response_data=None):
        """Log test result"""
        status = "✅ PASS" if success else "❌ FAIL"
        result = {
            "test": test_name,
            "status": status,
            "success": success,
            "details": details,
            "timestamp": datetime.now().isoformat()
        }
        if response_data:
            result["response_data"] = response_data
        self.test_results.append(result)
        print(f"{status} {test_name}: {details}")

    def make_request(self, method, endpoint, data=None, headers=None):
        """Make HTTP request with error handling"""
        url = f"{self.base_url}{endpoint}"
        
        if headers is None:
            headers = {}
        
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        
        headers["Content-Type"] = "application/json"
        
        try:
            if method.upper() == "GET":
                response = self.session.get(url, headers=headers, timeout=10)
            elif method.upper() == "POST":
                response = self.session.post(url, json=data, headers=headers, timeout=10)
            elif method.upper() == "PUT":
                response = self.session.put(url, json=data, headers=headers, timeout=10)
            elif method.upper() == "DELETE":
                response = self.session.delete(url, headers=headers, timeout=10)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            return response
        except requests.exceptions.RequestException as e:
            print(f"❌ Request failed for {method} {url}: {str(e)}")
            return None

    def test_1_authentication(self):
        """Test 1: Basis-Authentifikation"""
        print("\n" + "="*60)
        print("TEST 1: BASIS-AUTHENTIFIKATION")
        print("="*60)
        
        # Test 1.1: Demo User Login
        print("\n1.1 Testing Demo User Login...")
        response = self.make_request("POST", "/auth/login", self.demo_user)
        
        if response and response.status_code == 200:
            data = response.json()
            self.auth_token = data.get("access_token")
            self.current_user = data.get("user")
            self.log_result("Demo User Login", True, f"Logged in as {self.current_user.get('username', 'Unknown')}")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            if response:
                try:
                    error_detail = response.json().get('detail', 'Unknown error')
                    error_msg += f", Detail: {error_detail}"
                except:
                    error_msg += f", Response: {response.text[:100]}"
            self.log_result("Demo User Login", False, error_msg)
            return False
        
        # Test 1.2: Get Current User Info
        print("\n1.2 Testing Get Current User Info...")
        response = self.make_request("GET", "/auth/me")
        
        if response and response.status_code == 200:
            user_data = response.json()
            self.log_result("Get Current User", True, f"Retrieved user: {user_data.get('username')}")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get Current User", False, error_msg)
        
        # Test 1.3: User Registration
        print("\n1.3 Testing User Registration...")
        test_user = self.test_users[0].copy()
        response = self.make_request("POST", "/auth/register", test_user)
        
        if response and response.status_code == 200:
            user_data = response.json()
            self.log_result("User Registration", True, f"Created user: {user_data.get('username')}")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            if response and response.status_code == 400:
                try:
                    error_detail = response.json().get('detail', 'Unknown error')
                    if "already registered" in error_detail:
                        self.log_result("User Registration", True, f"User already exists (expected): {error_detail}")
                    else:
                        self.log_result("User Registration", False, error_msg + f", Detail: {error_detail}")
                except:
                    self.log_result("User Registration", False, error_msg)
            else:
                self.log_result("User Registration", False, error_msg)
        
        # Test 1.4: Profile Update
        print("\n1.4 Testing Profile Update...")
        profile_update = {
            "username": "Demo Benutzer (Aktualisiert)",
            "phone": "+49 30 99999999",
            "status": "Einsatz"
        }
        response = self.make_request("PUT", "/auth/profile", profile_update)
        
        if response and response.status_code == 200:
            updated_user = response.json()
            self.log_result("Profile Update", True, f"Updated profile: {updated_user.get('username')}")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Profile Update", False, error_msg)
        
        return True

    def test_2_incident_management(self):
        """Test 2: Incident Management"""
        print("\n" + "="*60)
        print("TEST 2: INCIDENT MANAGEMENT")
        print("="*60)
        
        # Test 2.1: Create Incidents
        print("\n2.1 Testing Incident Creation...")
        created_incidents = []
        
        for i, incident_data in enumerate(self.test_incidents):
            response = self.make_request("POST", "/incidents", incident_data)
            
            if response and response.status_code == 200:
                incident = response.json()
                created_incidents.append(incident)
                self.log_result(f"Create Incident {i+1}", True, f"Created: {incident.get('title')}")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result(f"Create Incident {i+1}", False, error_msg)
        
        # Test 2.2: Get All Incidents
        print("\n2.2 Testing Get All Incidents...")
        response = self.make_request("GET", "/incidents")
        
        if response and response.status_code == 200:
            incidents = response.json()
            self.log_result("Get All Incidents", True, f"Retrieved {len(incidents)} incidents")
            
            # Verify incident structure
            if incidents:
                incident = incidents[0]
                required_fields = ['id', 'title', 'description', 'priority', 'status', 'location', 'address', 'created_at']
                missing_fields = [field for field in required_fields if field not in incident]
                if missing_fields:
                    self.log_result("Incident Structure", False, f"Missing fields: {missing_fields}")
                else:
                    self.log_result("Incident Structure", True, "All required fields present")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get All Incidents", False, error_msg)
        
        # Test 2.3: Assign Incident (if we have incidents)
        if created_incidents:
            print("\n2.3 Testing Incident Assignment...")
            incident_id = created_incidents[0]['id']
            response = self.make_request("PUT", f"/incidents/{incident_id}/assign")
            
            if response and response.status_code == 200:
                assigned_incident = response.json()
                self.log_result("Assign Incident", True, f"Assigned to: {assigned_incident.get('assigned_to_name')}")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result("Assign Incident", False, error_msg)
        
        # Test 2.4: Complete Incident (if we have incidents)
        if created_incidents and len(created_incidents) > 1:
            print("\n2.4 Testing Incident Completion...")
            incident_id = created_incidents[1]['id']
            response = self.make_request("PUT", f"/incidents/{incident_id}/complete")
            
            if response and response.status_code == 200:
                result = response.json()
                self.log_result("Complete Incident", True, f"Completed and archived: {result.get('archive_id')}")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result("Complete Incident", False, error_msg)

    def test_3_user_management(self):
        """Test 3: User Management"""
        print("\n" + "="*60)
        print("TEST 3: USER MANAGEMENT")
        print("="*60)
        
        # Test 3.1: Get All Users (Admin only)
        print("\n3.1 Testing Get All Users...")
        response = self.make_request("GET", "/users")
        
        if response and response.status_code == 200:
            users = response.json()
            self.log_result("Get All Users", True, f"Retrieved {len(users)} users")
        elif response and response.status_code == 403:
            self.log_result("Get All Users", True, "Access denied (expected for non-admin)")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get All Users", False, error_msg)
        
        # Test 3.2: Get Users by Status
        print("\n3.2 Testing Get Users by Status...")
        response = self.make_request("GET", "/users/by-status")
        
        if response and response.status_code == 200:
            users_by_status = response.json()
            total_users = sum(len(users) for users in users_by_status.values())
            self.log_result("Get Users by Status", True, f"Retrieved {total_users} users in {len(users_by_status)} status groups")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get Users by Status", False, error_msg)
        
        # Test 3.3: Online Status Management
        print("\n3.3 Testing Online Status...")
        response = self.make_request("POST", "/users/online-status")
        
        if response and response.status_code == 200:
            status_data = response.json()
            self.log_result("Set Online Status", True, f"Status: {status_data.get('status')}")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Set Online Status", False, error_msg)
        
        # Test 3.4: Get Online Users
        print("\n3.4 Testing Get Online Users...")
        response = self.make_request("GET", "/users/online")
        
        if response and response.status_code == 200:
            online_users = response.json()
            self.log_result("Get Online Users", True, f"Found {len(online_users)} online users")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get Online Users", False, error_msg)

    def test_4_message_system(self):
        """Test 4: Message System"""
        print("\n" + "="*60)
        print("TEST 4: MESSAGE SYSTEM")
        print("="*60)
        
        # Test 4.1: Send Messages
        print("\n4.1 Testing Send Messages...")
        sent_messages = []
        
        for i, message_data in enumerate(self.test_messages):
            response = self.make_request("POST", "/messages", message_data)
            
            if response and response.status_code == 200:
                message = response.json()
                sent_messages.append(message)
                self.log_result(f"Send Message {i+1}", True, f"Sent to {message.get('channel')}: {message.get('content')[:30]}...")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result(f"Send Message {i+1}", False, error_msg)
        
        # Test 4.2: Get Messages by Channel
        print("\n4.2 Testing Get Messages by Channel...")
        channels = ["general", "emergency", "incidents"]
        
        for channel in channels:
            response = self.make_request("GET", f"/messages?channel={channel}")
            
            if response and response.status_code == 200:
                messages = response.json()
                self.log_result(f"Get Messages ({channel})", True, f"Retrieved {len(messages)} messages")
                
                # Verify message structure
                if messages:
                    message = messages[0]
                    required_fields = ['id', 'content', 'sender_id', 'sender_name', 'channel', 'timestamp']
                    missing_fields = [field for field in required_fields if field not in message]
                    if missing_fields:
                        self.log_result(f"Message Structure ({channel})", False, f"Missing fields: {missing_fields}")
                    else:
                        self.log_result(f"Message Structure ({channel})", True, "All required fields present")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result(f"Get Messages ({channel})", False, error_msg)

    def test_5_reports_system(self):
        """Test 5: Reports System"""
        print("\n" + "="*60)
        print("TEST 5: REPORTS SYSTEM")
        print("="*60)
        
        # Test 5.1: Create Reports
        print("\n5.1 Testing Create Reports...")
        created_reports = []
        
        for i, report_data in enumerate(self.test_reports):
            response = self.make_request("POST", "/reports", report_data)
            
            if response and response.status_code == 200:
                report = response.json()
                created_reports.append(report)
                self.log_result(f"Create Report {i+1}", True, f"Created: {report.get('title')}")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result(f"Create Report {i+1}", False, error_msg)
        
        # Test 5.2: Get All Reports
        print("\n5.2 Testing Get All Reports...")
        response = self.make_request("GET", "/reports")
        
        if response and response.status_code == 200:
            reports = response.json()
            self.log_result("Get All Reports", True, f"Retrieved {len(reports)} reports")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get All Reports", False, error_msg)
        
        # Test 5.3: Get Report Folders
        print("\n5.3 Testing Get Report Folders...")
        response = self.make_request("GET", "/reports/folders")
        
        if response and response.status_code == 200:
            folders = response.json()
            self.log_result("Get Report Folders", True, f"Retrieved {len(folders)} folders")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get Report Folders", False, error_msg)
        
        # Test 5.4: Update Report (if we have reports)
        if created_reports:
            print("\n5.4 Testing Update Report...")
            report_id = created_reports[0]['id']
            update_data = {
                "title": "Aktualisierter Schichtbericht",
                "content": "Dieser Bericht wurde aktualisiert mit zusätzlichen Informationen.",
                "shift_date": "2025-01-15"
            }
            response = self.make_request("PUT", f"/reports/{report_id}", update_data)
            
            if response and response.status_code == 200:
                updated_report = response.json()
                self.log_result("Update Report", True, f"Updated: {updated_report.get('title')}")
            else:
                error_msg = f"Status: {response.status_code if response else 'No response'}"
                self.log_result("Update Report", False, error_msg)

    def test_6_admin_functions(self):
        """Test 6: Admin Functions"""
        print("\n" + "="*60)
        print("TEST 6: ADMIN FUNCTIONS")
        print("="*60)
        
        # Test 6.1: Get Admin Stats
        print("\n6.1 Testing Get Admin Stats...")
        response = self.make_request("GET", "/admin/stats")
        
        if response and response.status_code == 200:
            stats = response.json()
            self.log_result("Get Admin Stats", True, f"Stats: {stats}")
        elif response and response.status_code == 403:
            self.log_result("Get Admin Stats", True, "Access denied (expected for non-admin)")
        else:
            error_msg = f"Status: {response.status_code if response else 'No response'}"
            self.log_result("Get Admin Stats", False, error_msg)

    def run_all_tests(self):
        """Run all tests in sequence"""
        print("🚀 Starting Comprehensive Backend API Testing for German Stadtwache App")
        print(f"🔗 Testing against: {self.base_url}")
        print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Run tests in order
        if not self.test_1_authentication():
            print("❌ Authentication failed - stopping tests")
            return False
        
        self.test_2_incident_management()
        self.test_3_user_management()
        self.test_4_message_system()
        self.test_5_reports_system()
        self.test_6_admin_functions()
        
        # Print summary
        self.print_summary()
        return True

    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        
        total_tests = len(self.test_results)
        passed_tests = len([r for r in self.test_results if r['success']])
        failed_tests = total_tests - passed_tests
        
        print(f"📊 Total Tests: {total_tests}")
        print(f"✅ Passed: {passed_tests}")
        print(f"❌ Failed: {failed_tests}")
        print(f"📈 Success Rate: {(passed_tests/total_tests*100):.1f}%")
        
        if failed_tests > 0:
            print(f"\n❌ FAILED TESTS:")
            for result in self.test_results:
                if not result['success']:
                    print(f"   • {result['test']}: {result['details']}")
        
        print(f"\n⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    tester = StadtwacheAPITester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)