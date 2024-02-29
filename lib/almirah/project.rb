require 'fileutils'
require_relative "doc_fabric"
require_relative "navigation_pane"
require_relative "doc_types/traceability"
require_relative "doc_types/coverage"

class Project

    attr_accessor :specifications
    attr_accessor :protocols
    attr_accessor :project_root_directory
    attr_accessor :specifications_dictionary

    def initialize(path)
        @project_root_directory = path
        @specifications = Array.new
        @protocols = Array.new
        @specifications_dictionary = Hash.new
        
        FileUtils.remove_dir(@project_root_directory + "/build", true)      
    end

    def specifications_and_protocols

        parse_all_specifications
        parse_all_protocols
        link_all_specifications
        link_all_protocols
        render_all_specifications
        render_all_protocols
    end

    def specifications_and_results( test_run )

        parse_all_specifications
        parse_test_run test_run
        link_all_specifications
        link_all_protocols
        render_all_specifications
        render_all_protocols
    end

    def parse_all_specifications        
        Dir.glob( "#{@project_root_directory}/specifications/**/*.md" ).each do |f|
            puts "Spec: " + f
            doc = DocFabric.create_specification(f)
            @specifications.append(doc)
        end
    end

    def parse_all_protocols
        Dir.glob( "#{@project_root_directory}/tests/protocols/**/*.md" ).each do |f|
            puts "Prot: " + f
            doc = DocFabric.create_protocol(f)
            @protocols.append(doc)
        end
    end

    def parse_test_run( test_run )
        Dir.glob( "#{@project_root_directory}/tests/runs/#{test_run}/**/*.md" ).each do |f|
            puts "Run: " + f
            doc = DocFabric.create_protocol(f)
            @protocols.append(doc)
        end
    end

    def link_all_specifications
        combList = @specifications.combination(2)
        combList.each do |c|
            link_two_specifications(c[0], c[1])
        end
    end

    def link_all_protocols
        @protocols.each do |p|
            @specifications.each do |s|
                if s.id == p.up_link_doc_id
                    link_protocol_to_spec(p,s)
                end
            end
        end
    end

    def link_two_specifications(doc_A, doc_B)

        if doc_A.id == doc_B.up_link_doc_id
            top_document = doc_A
            bottom_document = doc_B
        elsif doc_B.id == doc_A.up_link_doc_id
            top_document = doc_B
            bottom_document = doc_A
        else
            puts "No Links"
            return # no links
        end
        
        bottom_document.controlled_items.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.down_links
                    topItem.down_links = Array.new
                    top_document.items_with_downlinks_number += 1   # for statistics
                end
                topItem.down_links.append(item)
            end
        end
        # create treceability document
        trx = Traceability.new top_document, bottom_document
        @specifications.append trx
    end

    def link_protocol_to_spec(protocol, specification)

        top_document = specification
        bottom_document = protocol

        bottom_document.controlled_items.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.coverage_links
                    topItem.coverage_links = Array.new
                    top_document.items_with_coverage_number += 1    # for statistics
                end
                topItem.coverage_links.append(item)
            end
        end
        # create coverage document
        trx = Coverage.new top_document
        @specifications.append trx
    end

    def render_all_specifications
        
        # create a sidebar first
        nav_pane = NavigationPane.new(@specifications)        

        pass = @project_root_directory

        FileUtils.mkdir_p(pass + "/build/specifications")
    
        @specifications.each do |doc|

            doc.to_console

            img_src_dir = pass + "/specifications/" + doc.id + "/img"
            img_dst_dir = pass + "/build/specifications/" + doc.id + "/img"
     
            FileUtils.mkdir_p(img_dst_dir)

            if File.directory?(img_src_dir)
                FileUtils.copy_entry( img_src_dir, img_dst_dir )
            end

            doc.to_html( nav_pane, "#{pass}/build/specifications/" )
        end
    end

    def render_all_protocols
        
        # create a sidebar first
        nav_pane = NavigationPane.new(@specifications)        

        pass = @project_root_directory

        # FileUtils.remove_dir(pass + "/build/tests", true)
        FileUtils.mkdir_p(pass + "/build/tests/protocols")
    
        @protocols.each do |doc|

            img_src_dir = pass + "/tests/protocols/" + doc.id + "/img"
            img_dst_dir = pass + "/build/tests/protocols/" + doc.id + "/img"
     
            FileUtils.mkdir_p(img_dst_dir)

            if File.directory?(img_src_dir)
                FileUtils.copy_entry( img_src_dir, img_dst_dir )
            end

            doc.to_html( nav_pane, "#{pass}/build/tests/protocols/" )
        end
    end
end