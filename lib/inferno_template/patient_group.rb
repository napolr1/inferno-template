
require "uri"
require "json"
require "net/http"
require 'webmock/rspec'
require 'logger'

module InfernoTemplate
 
	class PatientGroup < Inferno::TestGroup
			title 'Patient  Tests'
			description 'Verify that the server makes Patient resources available'
			id :patient_group
			test do
				title 'Test whether it is possible to gain access to patient data without authenticating'
				description %(Test whether it is possible to gain access to patient data without authenticating)  

				input :search_json ,
				type: 'textarea'
				 
				
				fhir_client  do
    			  url :url
    			end	
							
		   
				run do 
					body = JSON[search_json] 
				  	fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type': 'application/fhir+json' })
  				  	assert_response_status(401) 
					   
				end
			end
				
			test do
			  title 'Patient match is valid'
			  description %(
				Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
			  )
			  
			  input 	:search_json ,
							type: 'textarea'
			  input  	:access_token
			  output 	:custom_headers
			  output 	:response_json
			  # Named requests can be used by other tests
			  makes_request :match
			  
			  

			  logger= Logger.new(STDOUT)
			  # create a named client for a group
			  
			  fhir_client  do
				url :url
			  end
			  
			  run do
					body = JSON[search_json] 
					custom_headers={'Content-Type': 'application/fhir+json', 'Authorization': 'Bearer ' +access_token};
					#fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type': 'application/fhir+json', 'Authorization': 'Bearer ' +authorization_bearer_token)
					fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers:  custom_headers)

					responseBody= response[:body] 

					output response_json: response[:body] 
					assert_response_status(200) 
					 
			  end
			end
			test do
			  input :expectedResultCnt
			  input :response_json
			  output :numberOfRecordsReturned
			  title 'Patient match - determines whether or not the $match function returns every valid record'
			  description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits
			  )
			  uses_request :match
			  run do
				
				  #puts response_json  
				  response = JSON[response_json]
				  assert_valid_json(response_json, message = "Invalid JSON response received - expected: #{expectedResultCnt} - received: #{numberOfRecordsReturned}")
				  numberOfRecordsReturned = response['total'] 
				  puts "number of records returned in bundle ---- #{numberOfRecordsReturned} " 
				  puts "number of records expected in bundle ---- #{expectedResultCnt} " 
				  assert numberOfRecordsReturned.to_i() == expectedResultCnt.to_i(), "Incorrect Number of Records returned"
				  
				  output numberOfRecordsReturned: numberOfRecordsReturned

				  #output :response_json response
				 
			  end
			
			end

			test do
			  input :expectedResultCnt
			  input :response_json 
			  title 'Determine whether or not the records are sorted by ID and Score'
			  description %(Match output SHOULD return records sorted by score      )
			  uses_request :match
			  run do
				
				
			
		  
			 
				  i =0 
				  curr_id=0
				  prev_id=0
				  curr_score=0
				  prev_score=0
				  is_sorted=true
		 
				  responseJSON = JSON.parse(response_json)
		 
		 
				  responseJSON["entry"].each do |item|
						puts "#{item}"
						puts "#{item} entry: #{item["entry"]}" 
						
						curr_score= item["resource"]["score"]
						curr_id=item["resource"]["id"]
						#puts  "Current Patient ID=#{curr_id}  Patient Score=#{curr_score}"
						#puts  "Current Patient ID=#{curr_id} "
						if i  > 0 

						  if prev_id.to_s >= curr_id.to_s && prev_score.to_s <= curr_score_to_s
							is_sorted=false 
						  end 
						  
						  prev_score=curr_score              
						  prev_id=curr_id
						  i= i + 1 
						  
						end
					end
				  puts "@@@@@@@@@@@@@   Is Sorted=#{is_sorted}  @@@@@@@@@@"
				  assert is_sorted == true, "Returned records are not sorted by patient id ( asc ) and score ( desc) "
				 
			  end      
			end
			test do
			  input :response_json 
			  title 'Determine whether or not  the patient.link field references an underlying patient'
			  description %(Determine whether or not  the patient.link field references an underlying patient    )
			   

			  run do
				
					   
=begin					response_json={
						"resourceType": "Bundle",
						"id": "a3f7e13c-bdab-4eda-83b0-1b87c1ebaf4f",				
						"type": "searchset",
						"total": 4,
						"entry": [
							{
								"resource": {
									"resourceType": "Patient",
									"id": "pat013",
									"meta": {
										"versionId": "1",
										"lastUpdated": "2019-06-13T09:55:51.116-04:00"
									},
									"text": {
										"status": "generated"
									},
									"identifier": [
										{
											"type": {
												"coding": [
													{
														"system": "http://hl7.org/fhir/sid/us-medicare",
														"code": "NIIP",
														"display": "US Medicare Payor Identifier"
													}
												],
												"text": "US Medicare Payor Identifier"
											},
											"value": "98765400001VQ"
										}
									],
									"name": [
										{
											"use": "official",
											"family": "Quinton",
											"given": [
												"Vlad",
												"Alan"
											]
										}
									],
									"gender": "male",
									"birthDate": "1956-12-01",
									"address": [
										{
											"use": "home",
											"type": "physical",
											"line": [
												"321 S Maple Dr"
											],
											"city": "Scranton",
											"state": "PA",
											"postalCode": "18503"
										}
									],
									"maritalStatus": {
										"coding": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
												"code": "UNK"
											}
										]
									},
									"link": [
										{
											"other": {
												"reference": "Patient/pat013"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1433204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/151204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1244780"
											}
										}
									]
								}
							},
							{
								"resource": {
									"resourceType": "Patient",
									"id": "1433204",
									"meta": {
										"versionId": "1",
										"lastUpdated": "2020-06-22T07:37:44.914+00:00",
										"source": "#Hep7oN0aHNPLwGdq",
										"tag": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-ObservationValue",
												"code": "SUBSETTED",
												"display": "Resource encoded in summary mode"
											}
										]
									},
									"identifier": [
										{
											"type": {
												"coding": [
													{
														"system": "http://terminology.hl7.org/CodeSystem/v2-0203",
														"code": "NIIP",
														"display": "National Insurance Payor Identifier"
													}
												],
												"text": "National Insurance Payor Identifier"
											},
											"value": "9800010091"
										}
									],
									"name": [
										{
											"family": "Queetin",
											"given": [
												"Alan"
											]
										}
									],
									"telecom": [
										{
											"system": "email",
											"value": "vladqueenton@email.com",
											"use": "home"
										}
									],
									"gender": "male",
									"birthDate": "1956-12-01",
									"address": [
										{
											"use": "home",
											"type": "physical",
											"line": [
												"541 Fullton Dr"
											],
											"city": "Arlington",
											"state": "VA",
											"postalCode": "22503"
										}
									],
									"maritalStatus": {
										"coding": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
												"code": "M",
												"display": "Married"
											}
										]
									},
									"link": [
										{
											"other": {
												"reference": "Patient/pat013"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1433204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/151204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1244780"
											}
										}
									]
								}
							},
							{
								"resource": {
									"resourceType": "Patient",
									"id": "151204",
									"meta": {
										"versionId": "1",
										"lastUpdated": "2020-06-22T07:37:44.914+00:00",
										"source": "#Hep7oN0aHNPLwGdq",
										"tag": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-ObservationValue",
												"code": "SUBSETTED",
												"display": "Resource encoded in summary mode"
											}
										]
									},
									"identifier": [
										{
											"type": {
												"coding": [
													{
														"system": "http://terminology.hl7.org/CodeSystem/v2-0203",
														"code": "MR",
														"display": "Medical Record Number"
													}
												],
												"text": "Medical Record Number"
											},
											"value": "QA1976567"
										}
									],
									"name": [
										{
											"family": "Quintin",
											"given": [
												"Alan"
											]
										}
									],
									"telecom": [
										{
											"system": "phone",
											"value": "344-845-5689",
											"use": "mobile"
										}
									],
									"gender": "male",
									"birthDate": "1956-11-01",
									"address": [
										{
											"use": "home",
											"type": "physical",
											"line": [
												"541 Fullton Dr"
											],
											"city": "Arlington",
											"state": "VA",
											"postalCode": "22503"
										}
									],
									"maritalStatus": {
										"coding": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
												"code": "M"
											}
										]
									},
									"link": [
										{
											"other": {
												"reference": "Patient/pat013"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1433204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/151204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1244780"
											}
										}
									]
								}
							},
							{
								"resource": {
									"resourceType": "Patient",
									"id": "1244780",
									"meta": {
										"versionId": "1",
										"lastUpdated": "2020-06-22T07:37:44.914+00:00",
										"source": "#Hep7oN0aHNPLwGdq",
										"tag": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-ObservationValue",
												"code": "SUBSETTED",
												"display": "Resource encoded in summary mode"
											}
										]
									},
									"identifier": [
										{
											"type": {
												"coding": [
													{
														"system": "http://terminology.hl7.org/CodeSystem/v2-0203",
														"code": "DL",
														"display": "Drivers License"
													}
												],
												"text": "Drivers License"
											},
											"value": "Q147604567"
										},
										{
											"type": {
												"coding": [
													{
														"system": "http://terminology.hl7.org/CodeSystem/v2-0203",
														"code": "NIIP",
														"display": "National Insurance Payor Identifier"
													}
												],
												"text": "National Insurance Payor Identifier"
											},
											"value": "9800010077"
										}
									],
									"name": [
										{
											"family": "Queentin",
											"given": [
												"Vladimir"
											]
										}
									],
									"telecom": [
										{
											"system": "phone",
											"value": "344-845-5689",
											"use": "mobile"
										}
									],
									"gender": "male",
									"birthDate": "1956-12-01",
									"address": [
										{
											"use": "home",
											"type": "physical",
											"line": [
												"321 South Maple Street"
											],
											"city": "Scranton",
											"state": "PA",
											"postalCode": "18503"
										}
									],
									"maritalStatus": {
										"coding": [
											{
												"system": "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus",
												"code": "M"
											}
										]
									},
									"contact": [
										{
											"relationship": [
												{
													"coding": [
														{
															"system": "http://hl7.org/fhir/v2/0131",
															"code": "C",
															"display": "Emergency Contact"
														}
													]
												}
											],
											"telecom": [
												{
													"system": "phone",
													"value": "726-555-1094",
													"use": "home"
												}
											]
										}
									],
									"link": [
										{
											"other": {
												"reference": "Patient/pat013"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1433204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/151204"
											},
											"type": "seealso"
										},
										{
											"other": {
												"reference": "Patient/1244780"
											}
										}
									]
								}
							}
						]
					}
=end
					responseJSON = JSON.parse(response_json)
					#tmp=JSON[response_json]
					#responseJSON=JSON.parse(tmp)
					i=0
					responseJSON["entry"].each do |item|		 
						puts "got here"
						patientLinkList= item["resource"]["link"] 
						puts "****patient Link List=#{patientLinkList}"
						if !patientLinkList.nil?
							patientLinkList.each do |patient_link|
								puts "patient_link=#{patient_link}"
								patientURL=patient_link["other"]["reference"]
								puts "PatientLink URL=#{patientURL}"
								patientID=patientURL.sub("Patient/","");
								#fhir_operation(patientURL, body: "", client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })
								fhir_read(:patient, patientID, client: :with_custom_headers)
								assert_response_status(200)
								#assert_resource_type(:resource)
								i=i+1
							end
						end
				end
				   
				 
				   
				end
 			end 
 			
			test do 
				input :response_json 
				title 'Determine whether the weighted score of the returned patient resource is in compliance 
				with the level of assurance (e.g., IDI Patient 1, IDI Patient 2, etc ) asserted by the transmitting  party.'
				description %(Match output SHOULD return records sorted by score      ) 
				
				output :results
				uses_request :match
				run do
						puts "*********************  Get Response Object ****************"
						#responseJSON = JSON.parse(response_json)
						responseJSON=JSON[response_json]
						#responseJSON=JSON.parse(tmp)
						idi_patient_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient"
						idi_patient_l0_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0" 
						idi_patient_l1_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1" 
						results=""
						responseJSON["entry"].each do |entry|	 
								weighted_score= 0

								# Get Patient Name, Address, DOB and telecom info

								resourceID=entry["resource"]["id"]
								givenName=entry["resource"]["name"][0]["given"][0]
								familyName=entry["resource"]["name"][0]["family"] 
								homeAddressLine=""
								homeAddressCity=""
								emailAddress=""
								phoneNumber=""
								ppn_id=""
								other_id=""
								dl_id=""
								stid_id=""
								photo=""
								photo=entry["resource"]["photo"]
								telecomArray=[]

								telecomArray=entry["resource"]["telecom"]
								puts ("telecomArray = #{telecomArray}")
								if (  !telecomArray.nil?  ) 
									telecomArray.each do |telecom|
										if telecom["system"]="phone"
											phoneNumber=telecom["value"]
										elsif telecom["system"]="email"
											emailAddress=telecom["value"]
										end								 
									end # end do
								end #end if 
								
								
								birthDate=entry["birthDate"]
								identifierList= entry["resource"]["identifier"] 

								#get Patient Address Info
								addressList= entry["address"]
								if ( !addressList.nil?)
									addressList.each do |address|
										if  (address["use"]="home" and address["line"] != "" and address["city"] != "" ) 
											homeAddressLine=address["line"]
											homehomeAddressCity=address["city"]											
										end
									end #end do
								end #end if

								# Get Patient Identifiers
								patientID=""
								if ( !identifierList.nil? )
									identifierList.each do |identifier|
										
										thisID=identifier["type"]["text"]
										codingArray=identifier["type"]["coding"]
										if ( !codingArray.nil? )
											codingArray.each do |coding|
												code=coding["code"]
												if code == "PPN"  
													ppn_id=thisID 
													patientID=thisID
												elsif   ( code == "STID" )
													stid_id=thisID
													patientID=thisID
												elsif ( code== "DL")
													dl_id=thisID
													patientID=thisID
												else
													other_id=thisID	
													patientID=thisID
												end
											end #end do
										end #end if
									end	#end do	
								end #end if ( identifierList != :null )

								profileList= entry["resource"]["meta"]["profile"]
								if ( !profileList.nil? )
									idi_patient_l1=false
									idi_patient = false
									idi_patient_l0=false
 
									profileList.each do |profile|
										puts "****profile=#{profile}"  
										puts ("Patient record Id = #{resourceID} ****")
										# Only validate Patient and Condition bundle entries. Validate Patient
										# resources against the given profile, and Codition resources against the
										# base FHIR Condition resource.


									
										if profile == idi_patient_profile

											
											if ( (patientID!="" or emailAddress != ""  or phoneNumber != "" ) or  ( givenName!=""  && familyName!="" ) or
												( homeAddressLine!="" && homehomeAddressCity!="" ) or brithDate!="" )
												results+="patient with Resource ID of #{resourceID} passed IDI_PATIENT Level Testing <br>"
												idi_patient=true
											end
											output results: results 
											assert idi_patient == true

										elsif profile == idi_patient_l0_profile							
											
											if ( ppn_id !="")
												weighted_score=10
											end
											if ( dl_id != ""  or stid_id != "" )
												weighted_score=weighted_score + 10
											end
											if ( (homeAddressLine != "" and homehomeAddressCity != "" ) or 
												( other_id != "" ) or  
												( emailAddress != "" or phoneNumber != "" or photo!= "" ))
												weighted_score = weighted_score + 4
											end 

											if ( familyName != "" && givenName != "")
												weighted_score = weighted_score + 4
											end
											if ( birthDate != "")
												weighted_score += 2
											end
											if weighted_score >= 10 
												idi_patient_l0=true 
												results+="Patient with Resource ID of #{resourceID} passed IDI_PATIENT_0 Level Testing  - weighted score= #{weighted_score}     - "
											end
											output results: results 
											assert idi_patient_l0 == true

										elsif  profile == idi_patient_l1_profile
											puts ("**** got here Patient record Id = #{resourceID} ****")
											if ( ppn_id !="")
												weighted_score=10
											end
											if ( dl_id != ""  or stid_id != "" )
												weighted_score=weighted_score + 10
											end
											if ( (homeAddressLine!= "" and homehomeAddressCity != "" ) or 
												( other_id !="" ) or 
												( emailAddress != "" or phoneNumber != "" or photo!= "" ))
													weighted_score = weighted_score + 4
											end 

											if ( familyName != "" && givenName != "")
												weighted_score = weighted_score + 4
											end
											if ( birthDate != "")
												weighted_score += 2
											end
											puts ("Patient with Resource ID of #{resourceID}  IDI_PATIENT_1 Level Testing - weighted score= #{weighted_score}        -  ")

											if weighted_score >= 20 
												idi_patient_l1=true 
												results+="Patient with Resource ID of #{resourceID} passed IDI_PATIENT_1 Level Testing - weighted score= #{weighted_score}    -  "
												
											end
											puts ( "idi_patient_l1=#{idi_patient_l1}")
											output results: results 
											assert idi_patient_l1 == true
										else
											results+="Patient with Resource ID of #{resourceID} contains an invalid Identification Level #{profile}"

										end
									end

						end 
	  
				end
				
			end
		end
	end
end