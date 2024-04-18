require 'fileutils'
require_relative "doc_fabric"
require_relative "navigation_pane"
require_relative "doc_types/traceability"
require_relative "doc_types/coverage"
require_relative "doc_types/index"

class Project

    attr_accessor :specifications
    attr_accessor :protocols
    attr_accessor :traceability_matrices
    attr_accessor :coverage_matrices
    attr_accessor :project_root_directory
    attr_accessor :specifications_dictionary
    attr_accessor :index
    attr_accessor :project

    def initialize(path)
        @project_root_directory = path
        @specifications = Array.new
        @protocols = Array.new
        @traceability_matrices = Array.new
        @coverage_matrices = Array.new
        @specifications_dictionary = Hash.new
        @index = nil
        @project = self

        FileUtils.remove_dir(@project_root_directory + "/build", true)      
    end

    def specifications_and_protocols

        parse_all_specifications
        parse_all_protocols
        link_all_specifications
        link_all_protocols
        check_wrong_specification_referenced
        create_index
        render_all_specifications(@specifications)
        render_all_specifications(@traceability_matrices)
        render_all_specifications(@coverage_matrices)
        render_all_protocols
        render_index
    end

    def specifications_and_results( test_run )

        parse_all_specifications
        parse_test_run test_run
        link_all_specifications
        link_all_protocols
        check_wrong_specification_referenced
        create_index
        render_all_specifications(@specifications)
        render_all_specifications(@traceability_matrices)
        render_all_specifications(@coverage_matrices)
        render_all_protocols
        render_index
    end

    def transform( file_extension )
        transform_all_specifications file_extension 
    end

    def transform_all_specifications( file_extension )

        path = @project_root_directory

        # find all specifications
        Dir.glob( "#{@project_root_directory}/specifications/**/*.md" ).each do |f|
            puts f
            # make a copy with another extention to preserve the content
            f_directory = File.dirname(f)
            f_name = File.basename(f, File.extname(f)).downcase + "._md"
            FileUtils.copy_file( f, "#{f_directory}/#{f_name}")
            # transform the original one
            # but do nothing for now - TODO
        end
    end

    def parse_all_specifications
        # do a lasy pass first to get the list of documents id
        Dir.glob( "#{@project_root_directory}/specifications/**/*.md" ).each do |f|
            DocFabric.add_lazy_doc_id(f)
        end
        # parse documents in the second pass
        Dir.glob( "#{@project_root_directory}/specifications/**/*.md" ).each do |f|
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
            # puts "Link: #{c[0].id} - #{c[1].id}"
        end
    end

    def link_all_protocols
        @protocols.each do |p|
            @specifications.each do |s|
                if p.up_link_doc_id.has_key?(s.id.to_s)
                    link_protocol_to_spec(p,s)
                end
            end
        end
    end

    def check_wrong_specification_referenced

        available_specification_ids = Hash.new

        @specifications.each do |s|
            available_specification_ids[ s.id.to_s.downcase ] = s
        end

        @specifications.each do |s|
            s.up_link_doc_id.each do |key, value|
                unless available_specification_ids.has_key?(key)
                    # now key points to the doc_id that does not exist
                    wrong_doc_id = key
                    # find the item that reference to it
                    s.controlled_items.each do |item|
                        unless item.up_link_ids.nil?
                            item.up_link_ids.each do |up_link_id|
                                if tmp = /^([a-zA-Z]+)[-]\d+/.match(up_link_id) # SRS
                                    if tmp[1].downcase == wrong_doc_id
                                        # we got it finally!
                                        s.wrong_links_hash[ up_link_id.to_s ] = item
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    def link_two_specifications(doc_A, doc_B)

        if doc_B.up_link_doc_id.has_key?(doc_A.id.to_s)
            top_document = doc_A
            bottom_document = doc_B
        elsif doc_A.up_link_doc_id.has_key?(doc_B.id.to_s)
            top_document = doc_B
            bottom_document = doc_A
        else
            return # no links
        end
        #puts "Link: #{doc_A.id} - #{doc_B.id}" 
        bottom_document.controlled_items.each do |item|

            if item.up_link_ids
                item.up_link_ids.each do |up_lnk|

                    if top_document.dictionary.has_key?(up_lnk.to_s)

                        topItem = top_document.dictionary[up_lnk.to_s]
                        
                        unless topItem.down_links
                            topItem.down_links = Array.new
                            top_document.items_with_downlinks_number += 1   # for statistics
                        end
                        topItem.down_links.append(item)
                    else
                        # check if there is a non existing link with the right doc_id
                        if tmp = /^([a-zA-Z]+)[-]\d+/.match(up_lnk) # SRS
                            if tmp[1].downcase == top_document.id.downcase
                                bottom_document.wrong_links_hash[ up_lnk ] = item
                            end
                        end
                    end
                end
            end
        end
        # create treceability document
        trx = Traceability.new top_document, bottom_document, false
        @traceability_matrices.append trx
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
        @coverage_matrices.append trx
    end

    def create_index
        @index = Index.new( @project )
    end

    def render_all_specifications(spec_list)
        
        # create a sidebar first
        # nav_pane = NavigationPane.new(@specifications)        

        pass = @project_root_directory

        FileUtils.mkdir_p(pass + "/build/specifications")
    
        spec_list.each do |doc|

            doc.to_console

            img_src_dir = pass + "/specifications/" + doc.id + "/img"
            img_dst_dir = pass + "/build/specifications/" + doc.id + "/img"
     
            FileUtils.mkdir_p(img_dst_dir)

            if File.directory?(img_src_dir)
                FileUtils.copy_entry( img_src_dir, img_dst_dir )
            end

            doc.to_html( nil, "#{pass}/build/specifications/" )
        end
    end

    def render_all_protocols
        
        # create a sidebar first
        # nav_pane = NavigationPane.new(@specifications)        

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

            doc.to_html( nil, "#{pass}/build/tests/protocols/" )
        end
    end

    def render_index    

        path = @project_root_directory

        doc = @index
        doc.to_console

        doc.to_html("#{path}/build/")
    end
end