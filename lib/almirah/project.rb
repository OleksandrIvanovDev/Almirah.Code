require_relative "doc_fabric"
require_relative "html_render"
require_relative "navigation_pane"

class Project

    attr_accessor :specifications
    attr_accessor :protocols
    attr_accessor :project_root_directory
    attr_accessor :gem_root
    attr_accessor :specifications_dictionary

    def initialize(path, gem_root)
        @project_root_directory = path
        @specifications = Array.new
        @protocols = Array.new
        @gem_root = gem_root
        @specifications_dictionary = Hash.new
        
        parse_all_documents()
        link_all_specifications()
        #link_all_protocols()
        render_all_specifications()
       
    end

    def parse_all_documents
        
        Dir.glob( "#{@project_root_directory}/specifications/**/*.md" ).each do |f|
            puts "Spec: " + f
            doc = DocFabric.create_specification(f)
            @specifications.append(doc)
        end
        Dir.glob( "#{@project_root_directory}/tests/protocols/**/*.md" ).each do |f|
            puts "Prot: " + f
            doc = DocFabric.create_protocol(f)
            @protocols.append(doc)
        end
    end

    def link_all_specifications
        combList = @specifications.combination(2)
        combList.each do |c|
            self.link_two_specifications(c[0], c[1])
        end
    end

    def link_all_protocols
        @protocols.each do |p|
            @specifications.each do |s|
                if s.id == p.up_link_key
                    link_protocol_to_spec(p,s)
                end  
            end
        end
    end

    def link_two_specifications(doc_A, doc_B)

        if doc_A.id == doc_B.up_link_key
            top_document = doc_A
            bottom_document = doc_B
        elsif doc_B.id == doc_A.up_link_key
            top_document = doc_B
            bottom_document = doc_A
        else
            puts "No Links"
            return # no links
        end

        bottom_document.controlled_paragraphs.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.down_links
                    topItem.down_links = Array.new
                end
                topItem.down_links.append(item)

                #if tmp = /^([a-zA-Z]+)[-]\d+/.match(item.id)
                #    top_document.downlinkKey = tmp[1].upcase
                #end
            end
        end
    end

    def link_protocol_to_spec(protocol, specification)

        top_document = specification
        bottom_document = protocol

        bottom_document.controlled_paragraphs.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.coverage_links
                    topItem.coverage_links = Array.new
                end
                topItem.coverage_links.append(item)
            end
        end
    end

    def render_all_specifications
        
        # create a sidebar first
        nav_pane = NavigationPane.new(@specifications)        

        pass = @project_root_directory

        FileUtils.remove_dir(pass + "/build", true)
        FileUtils.mkdir_p(pass + "/build/specifications")
    
        @specifications.each do |spec|

            img_src_dir = pass + "/specifications/" + spec.id.downcase + "/img"
            img_dst_dir = pass + "/build/specifications/" + spec.id.downcase + "/img"
     
            FileUtils.mkdir_p(img_dst_dir)

            if File.directory?(img_src_dir)
                FileUtils.copy_entry( img_src_dir, img_dst_dir )
            end

            HtmlRender.new( spec, nav_pane,
            @gem_root + "/lib/almirah/templates/page.html",
            "#{pass}/build/specifications/#{spec.id.downcase}/#{spec.id.downcase}.html" )
        end
    end
end