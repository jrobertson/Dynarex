#!/usr/bin/ruby

require 'rexml/document'
require 'open-uri'
require 'builder'

class Dynarex
  include REXML 

  def initialize(location)
    open(location)
  end

  def summary
    @summary
  end

  def records
    @records
  end
  
  def save(filepath)
    
    xml = Builder::XmlMarkup.new( :target => buffer='', :indent => 2 )
    xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    xml.send @root_name do
      xml.summary do
        dynarex.summary.each{|key,value| xml.send key, value}
      end
      xml.records do
        dynarex.records.each do |item|
          xml.send @item_name do
            item.each do |key, value| 
              xml.send key, value
            end
          end
        end  
      end
    end    
    
    File.open(filepath,'w'){|f| f.write buffer}
  end

  private

  def open(location)
    if location[/^https?:\/\//] then
      buffer = Kernel.open(location, 'UserAgent' => 'Dynarex-Reader').read
    elsif location[/\</]
      buffer = location
    else
      buffer = File.open(location,'r').read
    end
    @doc = Document.new buffer
    @summary = summary_to_h
    @records = records_to_h
    @root_name = doc.root.name
    @item_name = XPath.first(@doc.root, 'records/*[1]').name    
  end  

  def display()
    puts @doc.to_s
  end

  def records_to_h
    XPath.match(@doc.root, 'records/*').map do |row|
      XPath.match(row, '*').inject({}) do |r,node|
        r[node.name.to_s.to_sym] = node.text.to_s
        r
      end
    end
  end

  def summary_to_h
    XPath.match(@doc.root, 'summary/*').inject({}) do |r,node|
      r[node.name.to_s.to_sym] = node.text.to_s
      r
    end
  end

end
