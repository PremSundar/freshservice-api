require 'rest_client'
require 'nokogiri'
require 'uri'

class Freshservice

  # custom errors
  class AlreadyExistedError < StandardError; end
  class ConnectionError < StandardError; end

  attr_accessor :base_url

  def initialize(base_url, username, password='X')

    @base_url = base_url
    @auth = {:user => username, :password => password}
  end

  # Freshdesk API client support "GET" with id parameter optional
  #   Returns nil if there is no response
  def self.fd_define_get(name)
    name = name.to_s
    method_name = "get_" + name

    define_method method_name do |*args|
      uri = mapping(name)
      # If we've been passed a string paramter, it means we're fetching
      # something like domain_URL/helpdesk/tickets/[ticket_id].json
      #
      # If we're supplied with a hash parameter, it means we're fetching
      # something like domain_URL/helpdesk/tickets.json?filter_name=all_tickets&page=[value]
      if args.size > 0
        url_args = args.first
        if url_args.class == Hash
          uri += '?' + URI.encode_www_form(url_args)
        else
          uri.gsub!(/\.json/, "/#{url_args}.json")
        end
      end

      begin
        response = RestClient::Request.execute(@auth.merge(:method => :get, :url => uri))
      rescue Exception
        response = nil
      end
    end
  end

  # Certain GET calls require query strings instead of a more
  # RESTful URI. This method and fd_define_get are mutually exclusive.
  # def self.fd_define_parameterized_get(name)
  #   name = name.to_s
  #   method_name = "get_" + name

  #   define_method method_name do |params={}|
  #     uri = mapping(name)
  #     uri.gsub!(/\.json/, ".json")
  #     unless params.empty?
  #       uri += '?' + URI.encode_www_form(params)
  #     end

  #     begin
  #       response = RestClient::Request.execute(@auth.merge(:method => :get, :url => uri))
  #     rescue Exception
  #       response = nil
  #     end
  #   end
  # end

  # Freshdesk API client support "DELETE" with the required id parameter
  def self.fd_define_delete(name)
    name = name.to_s
    method_name = "delete_" + name
    define_method method_name do |args|
      uri = mapping(name)
      raise StandardError, "An ID is required to delete" if args.size.eql? 0
      uri.gsub!(/.json/, "/#{args}.json")
      RestClient::Request.execute(@auth.merge(:method => :delete, :url => uri))
    end
  end

  # Freshdesk API client support "POST" with the optional key, value parameter
  #
  #  Will throw:
  #    AlreadyExistedError if there is exact copy of data in the server
  #    ConnectionError     if there is connection problem with the server
  def self.fd_define_post(name)
    name = name.to_s
    method_name = "post_" + name

    define_method method_name do |args, id=nil|
      raise StandardError, "Arguments are required to modify data" if args.size.eql? 0
      id = args[:id]
      uri = mapping(name, id)

      builder = Nokogiri::XML::Builder.new do |json|
        json.send(doc_name(name)) {
          if args.has_key? :attachment
            attachment_name = args[:attachment][:name] or raise StandardError, "Attachment name required"
            attachment_cdata = args[:attachment][:cdata] or raise StandardError, "Attachment CDATA required"
            json.send("attachments", type: "array") {
              json.send("attachment") {
                json.send("resource", "type" => "file", "name" => attachment_name, "content-type" => "application/octet-stream") {
                  json.cdata attachment_cdata
                }
              }
            }
          args.except! :attachment
          end
          args.each do |key, value|
            json.send(key, value)
          end
        }
      end
      data = Hash.from_xml(builder.to_xml)
      begin
        options = @auth.merge(
          :method => :post,
          :payload => data,
          :headers => {:content_type => "text/json"},
          :url => uri
        )
        response = RestClient::Request.execute(options)
      rescue RestClient::UnprocessableEntity
        raise AlreadyExistedError, "Entry already existed"

      rescue RestClient::InternalServerError
        raise ConnectionError, "Connection to the server failed. Please check hostname"

      rescue RestClient::Found
        raise ConnectionError, "Connection to the server failed. Please check username/password"

      rescue Exception
        raise
      end

      response
    end
  end

  # Freshdesk API client support "PUT" with key, value parameter
  #
  #  Will throw:
  #    ConnectionError     if there is connection problem with the server
  def self.fd_define_put(name)
    name = name.to_s
    method_name = "put_" + name

    define_method method_name do |args|
      raise StandardError, "Arguments are required to modify data" if args.size.eql? 0
      raise StandardError, "id is required to modify data" if args[:id].nil?
      uri = mapping(name)

      builder = Nokogiri::XML::Builder.new do |json|
        json.send(doc_name(name)) {
          args.each do |key, value|
            json.send(key, value)
          end
        }
      end
      data = Hash.from_xml(builder.to_xml)
      begin
        uri.gsub!(/.json/, "/#{args[:id]}.json")
        options = @auth.merge(
          :method => :put,
          :payload => data,
          :headers => {:content_type => "text/json"},
          :url => uri
        )
        response = RestClient::Request.execute(options)
      rescue RestClient::InternalServerError
        raise ConnectionError, "Connection to the server failed. Please check hostname"

      rescue RestClient::Found
        raise ConnectionError, "Connection to the server failed. Please check username/password"

      rescue Exception
        raise
      end

      response
    end
  end

  [:tickets,  :problems, :changes, :releases, :users, :solutions, :departments, :config_items].each do |a|
    fd_define_get a
    fd_define_post a
    fd_define_delete a
    fd_define_put a
  end

  [:ticket_fields, :problem_fields, :change_fields, :release_fields, :ci_types, :ci_type_fields].each do |a|
    fd_define_get a
  end

  [:ticket_notes, :problem_notes, :change_notes, :release_notes].each do |a|
    fd_define_post a
  end

  # [:user_ticket].each do |resource|
  #   fd_define_parameterized_get resource
  # end


  # Mapping of object name to url:
  #   tickets => helpdesk/tickets.json
  #   ticket_fields => /ticket_fields.json
  #   users => /contacts.json
  #   forums => /categories.json
  #   solutions => /solution/categories.json
  #   companies => /customers.json
  def mapping(method_name, id = nil)
    case method_name
      when "tickets" then File.join(@base_url + "helpdesk/tickets.json")
      when "ticket_fields" then File.join(@base_url, "ticket_fields.json")
      when "ticket_notes" then File.join(@base_url, "helpdesk/tickets/#{id}/notes.json")
      when "problems" then File.join(@base_url + "itil/problems.json")
      when "problem_fields" then File.join(@base_url, "itil/problem_fields.json")
      when "problem_notes" then File.join(@base_url, "itil/problems/#{id}/notes.json")
      when "changes" then File.join(@base_url + "itil/changes.json")
      when "change_fields" then File.join(@base_url, "itil/change_fields.json")
      when "change_notes" then File.join(@base_url, "itil/changes/#{id}/notes.json")
      when "releases" then File.join(@base_url + "itil/releases.json")
      when "release_fields" then File.join(@base_url, "itil/release_fields.json")
      when "release_notes" then File.join(@base_url, "itil/releases/#{id}/notes.json")
      when "users" then File.join(@base_url, "itil/requesters.json")
      when "solutions" then File.join(@base_url + "solution/categories.json")
      when "departments" then File.join(@base_url + "itil/departments.json")
      when "config_items" then File.join(@base_url + "cmdb/items.json")
      when "ci_types" then File.join(@base_url + "cmdb/ci_types.json")
      when "ci_type_fields" then File.join(@base_url + "cmdb/ci_types.json")
      when "items" then File.join(@base_url + "catalog/items.json")
      when "categories" then File.join(@base_url + "catalog/categories.json")
    end
  end

  # match with the root name of json document that freshdesk uses
  def doc_name(name)
    case name
      when "tickets" then "helpdesk_ticket"
      # when "ticket_fields" then "helpdesk-ticket-fields"
      when "ticket_notes" then "helpdesk_note"
      when "problems" then "itil_problem"
      # when "problem_fields" then "itil_problem_fields"
      when "problem_notes" then "itil_note"
      when "changes" then "itil_change"
      # when "change_fields" then "itil_change_fields"
      when "change_notes" then "itil_note"
      when "releases" then "itil_release"
      # when "release_fields" then "itil_release_fields"
      when "release_notes" then "itil_note"
      when "users" then "user"
      when "departments" then "itil_department"
      when "config_items" then "cmdb_config_item"
      when "solutions" then "solution_category"
      else raise StandardError, "No root object for this call"
    end
  end
end