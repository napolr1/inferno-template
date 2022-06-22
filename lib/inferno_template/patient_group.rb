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
		  title 'Patient match is valid'
		  description %(
			Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
		  )
		  
		  input :search_json ,
			type: 'textarea'
		  
		  output :response_json
		  # Named requests can be used by other tests
		  makes_request :match
		  
		  

		  logger= Logger.new(STDOUT)
		  # create a named client for a group
		  fhir_client  do
			url :url
		  end
	 
		  run do
			body = JSON[search_json] 
			

			  #puts("request url=" +  url)
			  #puts("request body= #{body}" )
			  fhir_operation("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })

			  #puts("response body=" +  response[:body])
			  #fhir_operation("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })

			  
			  #response_json=response[:body]
			  output response_json: response[:body]
			  #output response_json: response_json
			  assert_response_status(200)
			  #assert_resource_type(:bundle)
				 
		  end
		end
		test do
		  input :expectedResultCnt
		  input :response_json
		  output :numberOfRecordsReturned
		  title 'Patient match - determines whether or not the $match function returns every valid record'
		  description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits
		  )
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
					puts  "Current Patient ID=#{curr_id}  Patient Score=#{curr_score}"
					puts  "Current Patient ID=#{curr_id} "
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
		  input :expectedResultCnt
		  input :response_json 

		  title 'Determine whether or not  the patient.link field references an underlying patient'
		  description %(Determine whether or not  the patient.link field references an underlying patient    )
		  run do

			  responseJSON = JSON.parse(response_json)
	 
	 
			  responseJSON["entry"].each do |item|
					 
					
					patientLinkURL= item["resource"]["link"] 
          puts "PatientLink URL=#{patientLinkURL}"
          #fhir_operation("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })
          assert_response_status(200)
			    assert_resource_type(:resource)
				
				end
			   
			 
		  end      
		end
	  end
	 
end