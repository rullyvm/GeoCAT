class GbifController < ApplicationController

    # begin SEARCH
    def search
      
      render :json => "{'Status':'Error'}" and return if params.empty?
      render :json => "{'Status':'Error'}" and return if params[:q].blank?

      q = params[:q]
      
      require 'open-uri'
      
      gbif_mirrors = %w(de.mirror.gbif.org us.mirror.gbif.org es.mirror.gbif.org data.gbif.org)
      
      gbif_mirrors.each do |mirror|
        begin
          gbif_url = URI.escape(
            "http://#{mirror}/ws" +
            "/rest/Occurrence/list?georeferencedonly=true&format=darwin" +
            "&maxresults=200&coordinateissues=false&scientificname=#{q}"
          )
          open(gbif_url) {|f| @list =  f.read }
          break
        rescue Exception=>e
        end
      end
      
      doc = Nokogiri::XML(@list)
      
      points = []
      doc.xpath("//gbif:occurrenceRecords/to:TaxonOccurrence").each do |node|
                    
        @institutionCode          = node.xpath("to:institutionCode").text
        @collectionCode           = node.xpath("to:collectionCode").text
        @catalogNumber            = node.xpath("to:catalogNumber").text
        @basisOfRecord            = node.xpath("to:basisOfRecordString").text
        @recordedBy               = node.xpath("to:collector").text
        @eventDate                = node.xpath("to:earliestDateCollected").text
        @country                  = node.xpath("to:country").text
        @stateProvince            = node.xpath("to:stateProvince").text
        @county                   = node.xpath("to:county").text
        @verbatimElevation        = node.xpath("to:maximumElevationInMeters").text
        @locality                 = node.xpath("to:locality").text
        @coordinateUncertaintyInMeters = node.xpath("to:coordinateUncertaintyInMeters").text
        @identifiedBy             = ""
        @occurrenceRemarks        = node.xpath("to:gbifNotes").text
        @gbifKey                  = node.attr('gbifKey')
        @occurrenceDetails        = "http://data.gbif.org/occurrences/" + @gbifKey
        @latitude                 = node.xpath("to:decimalLatitude").text.to_f
        @longitude                = node.xpath("to:decimalLongitude").text.to_f
        
        points << {"latitude"=> @latitude,"longitude"=> @longitude,
          "institutionCode"=>@institutionCode,
          "collectionCode"=>@collectionCode,
          "catalogNumber"=>@catalogNumber,
          "basisOfRecord"=>@basisOfRecord,
          "recordedBy"=>@recordedBy,
          "eventDate" =>@eventDate,
          "country"=>@country,
          "stateProvince"=>@stateProvince,
          "county"=>@county,
          "verbatimElevation"=>@verbatimElevation,
          "locality"=>@locality,
          "coordinateUncertaintyInMeters"=>@coordinateUncertaintyInMeters,
          "identifiedBy"=>@identifiedBy,
          "occurrenceRemarks"=>@occurrenceRemarks,
          "occurrenceDetails"=>@occurrenceDetails,
          "coordinateUncertaintyInMeters"=>"15",
          "collector"=>@recordedBy,
          "active"=>true,
          "removed"=>false,
          "catalogue_id"=>"gbif_#{@institutionCode}-#{@collectionCode}-#{@catalogNumber}",
          "kind"=>"gbif"}
      end

      @list =  [{"id"=>"gbif_id","name"=>"gbif","points"=> points }]

      render :json =>@list
    rescue Exception=> e
      render :json => "{'Status':'Error',message:'#{e.message}'}"
    end
    # end SEARCH
end
