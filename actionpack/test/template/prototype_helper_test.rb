require File.dirname(__FILE__) + '/../abstract_unit'

module BaseTest
  include ActionView::Helpers::JavaScriptHelper
  include ActionView::Helpers::PrototypeHelper
  
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::CaptureHelper
  
  def setup
    @controller = Class.new do
      def url_for(options, *parameters_for_method_reference)
        url =  "http://www.example.com/"
        url << options[:action].to_s if options and options[:action]
        url
      end
    end.new
  end

protected
  def create_generator
    block = Proc.new { |*args| yield *args if block_given? } 
    JavaScriptGenerator.new self, &block
  end
end

class PrototypeHelperTest < Test::Unit::TestCase
  include BaseTest
  
  def test_link_to_remote
    assert_dom_equal %(<a class=\"fine\" href=\"#\" onclick=\"new Ajax.Request('http://www.example.com/whatnot', {asynchronous:true, evalScripts:true}); return false;\">Remote outpost</a>),
      link_to_remote("Remote outpost", { :url => { :action => "whatnot"  }}, { :class => "fine"  })
    assert_dom_equal %(<a href=\"#\" onclick=\"new Ajax.Request('http://www.example.com/whatnot', {asynchronous:true, evalScripts:true, onComplete:function(request){alert(request.reponseText)}}); return false;\">Remote outpost</a>),
      link_to_remote("Remote outpost", :complete => "alert(request.reponseText)", :url => { :action => "whatnot"  })      
    assert_dom_equal %(<a href=\"#\" onclick=\"new Ajax.Request('http://www.example.com/whatnot', {asynchronous:true, evalScripts:true, onSuccess:function(request){alert(request.reponseText)}}); return false;\">Remote outpost</a>),
      link_to_remote("Remote outpost", :success => "alert(request.reponseText)", :url => { :action => "whatnot"  })
    assert_dom_equal %(<a href=\"#\" onclick=\"new Ajax.Request('http://www.example.com/whatnot', {asynchronous:true, evalScripts:true, onFailure:function(request){alert(request.reponseText)}}); return false;\">Remote outpost</a>),
      link_to_remote("Remote outpost", :failure => "alert(request.reponseText)", :url => { :action => "whatnot"  })
  end
  
  def test_periodically_call_remote
    assert_dom_equal %(<script type="text/javascript">\n//<![CDATA[\nnew PeriodicalExecuter(function() {new Ajax.Updater('schremser_bier', 'http://www.example.com/mehr_bier', {asynchronous:true, evalScripts:true})}, 10)\n//]]>\n</script>),
      periodically_call_remote(:update => "schremser_bier", :url => { :action => "mehr_bier" })
  end
  
  def test_form_remote_tag
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;\">),
      form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  })
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({success:'glass_of_beer'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;\">),
      form_remote_tag(:update => { :success => "glass_of_beer" }, :url => { :action => :fast  })
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({failure:'glass_of_water'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;\">),
      form_remote_tag(:update => { :failure => "glass_of_water" }, :url => { :action => :fast  })
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({success:'glass_of_beer',failure:'glass_of_water'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;\">),
      form_remote_tag(:update => { :success => 'glass_of_beer', :failure => "glass_of_water" }, :url => { :action => :fast  })
  end
  
  def test_on_callbacks
    callbacks = [:uninitialized, :loading, :loaded, :interactive, :complete, :success, :failure]
    callbacks.each do |callback|
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on#{callback.to_s.capitalize}:function(request){monkeys();}, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, callback=>"monkeys();")
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({success:'glass_of_beer'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on#{callback.to_s.capitalize}:function(request){monkeys();}, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => { :success => "glass_of_beer" }, :url => { :action => :fast  }, callback=>"monkeys();")
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({failure:'glass_of_beer'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on#{callback.to_s.capitalize}:function(request){monkeys();}, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => { :failure => "glass_of_beer" }, :url => { :action => :fast  }, callback=>"monkeys();")
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater({success:'glass_of_beer',failure:'glass_of_water'}, 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on#{callback.to_s.capitalize}:function(request){monkeys();}, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => { :success => "glass_of_beer", :failure => "glass_of_water" }, :url => { :action => :fast  }, callback=>"monkeys();")
    end
    
    #HTTP status codes 200 up to 599 have callbacks
    #these should work
    100.upto(599) do |callback|
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on#{callback.to_s.capitalize}:function(request){monkeys();}, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, callback=>"monkeys();")
    end
    
    #test 200 and 404
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on200:function(request){monkeys();}, on404:function(request){bananas();}, parameters:Form.serialize(this)}); return false;">),
      form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, 200=>"monkeys();", 404=>"bananas();")
    
    #these shouldn't
    1.upto(99) do |callback|
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, callback=>"monkeys();")
    end
    600.upto(999) do |callback|
      assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;">),
        form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, callback=>"monkeys();")
    end
    
    #test ultimate combo
    assert_dom_equal %(<form action=\"http://www.example.com/fast\" method=\"post\" onsubmit=\"new Ajax.Updater('glass_of_beer', 'http://www.example.com/fast', {asynchronous:true, evalScripts:true, on200:function(request){monkeys();}, on404:function(request){bananas();}, onComplete:function(request){c();}, onFailure:function(request){f();}, onLoading:function(request){c1()}, onSuccess:function(request){s()}, parameters:Form.serialize(this)}); return false;\">),
      form_remote_tag(:update => "glass_of_beer", :url => { :action => :fast  }, :loading => "c1()", :success => "s()", :failure => "f();", :complete => "c();", 200=>"monkeys();", 404=>"bananas();")
    
  end
  
  def test_submit_to_remote
    assert_dom_equal %(<input name=\"More beer!\" onclick=\"new Ajax.Updater('empty_bottle', 'http://www.example.com/', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this.form)}); return false;\" type=\"button\" value=\"1000000\" />),
      submit_to_remote("More beer!", 1_000_000, :update => "empty_bottle")
  end
  
  def test_observe_field
    assert_dom_equal %(<script type=\"text/javascript\">\n//<![CDATA[\nnew Form.Element.Observer('glass', 300, function(element, value) {new Ajax.Request('http://www.example.com/reorder_if_empty', {asynchronous:true, evalScripts:true})})\n//]]>\n</script>),
      observe_field("glass", :frequency => 5.minutes, :url => { :action => "reorder_if_empty" })
  end
  
  def test_observe_form
    assert_dom_equal %(<script type=\"text/javascript\">\n//<![CDATA[\nnew Form.Observer('cart', 2, function(element, value) {new Ajax.Request('http://www.example.com/cart_changed', {asynchronous:true, evalScripts:true})})\n//]]>\n</script>),
      observe_form("cart", :frequency => 2, :url => { :action => "cart_changed" })
  end

  def test_update_element_function
    assert_equal %($('myelement').innerHTML = 'blub';\n),
      update_element_function('myelement', :content => 'blub')
    assert_equal %($('myelement').innerHTML = 'blub';\n),
      update_element_function('myelement', :action => :update, :content => 'blub')
    assert_equal %($('myelement').innerHTML = '';\n),
      update_element_function('myelement', :action => :empty)
    assert_equal %(Element.remove('myelement');\n),
      update_element_function('myelement', :action => :remove)
      
    assert_equal %(new Insertion.Bottom('myelement','blub');\n),
      update_element_function('myelement', :position => 'bottom', :content => 'blub')
    assert_equal %(new Insertion.Bottom('myelement','blub');\n),
      update_element_function('myelement', :action => :update, :position => :bottom, :content => 'blub')
      
    _erbout = ""
    assert_equal %($('myelement').innerHTML = 'test';\n),
      update_element_function('myelement') { _erbout << "test" }
      
    _erbout = ""
    assert_equal %($('myelement').innerHTML = 'blockstuff';\n),
      update_element_function('myelement', :content => 'paramstuff') { _erbout << "blockstuff" }
  end
  
  def test_update_page
    block = Proc.new { |page| page.replace_html('foo', 'bar') }
    assert_equal create_generator(&block).to_s, update_page(&block)
  end
  
  def test_update_page_tag
    block = Proc.new { |page| page.replace_html('foo', 'bar') }
    assert_equal javascript_tag(create_generator(&block).to_s), update_page_tag(&block)
  end
end

class JavaScriptGeneratorTest < Test::Unit::TestCase
  include BaseTest
  
  def setup
    super
    @generator = create_generator
  end
  
  def test_insert_html_with_string
    assert_equal 'new Insertion.Top("element", "<p>This is a test</p>");',
      @generator.insert_html(:top, 'element', '<p>This is a test</p>')
    assert_equal 'new Insertion.Bottom("element", "<p>This is a test</p>");',
      @generator.insert_html(:bottom, 'element', '<p>This is a test</p>')
    assert_equal 'new Insertion.Before("element", "<p>This is a test</p>");',
      @generator.insert_html(:before, 'element', '<p>This is a test</p>')
    assert_equal 'new Insertion.After("element", "<p>This is a test</p>");',
      @generator.insert_html(:after, 'element', '<p>This is a test</p>')
  end
  
  def test_replace_html_with_string
    assert_equal 'Element.update("element", "<p>This is a test</p>");',
      @generator.replace_html('element', '<p>This is a test</p>')
  end
  
  def test_remove
    assert_equal '["foo"].each(Element.remove);',
      @generator.remove('foo')
    assert_equal '["foo", "bar", "baz"].each(Element.remove);',
      @generator.remove('foo', 'bar', 'baz')
  end
  
  def test_show
    assert_equal 'Element.show("foo");',
      @generator.show('foo')
    assert_equal 'Element.show("foo", "bar", "baz");',
      @generator.show('foo', 'bar', 'baz')
  end
  
  def test_hide
    assert_equal 'Element.hide("foo");',
      @generator.hide('foo')
    assert_equal 'Element.hide("foo", "bar", "baz");',
      @generator.hide('foo', 'bar', 'baz')
  end
  
  def test_alert
    assert_equal 'alert("hello");', @generator.alert('hello')
  end
  
  def test_redirect_to
    assert_equal 'window.location.href = "http://www.example.com/welcome";',
      @generator.redirect_to(:action => 'welcome')
  end
  
  def test_to_s
    @generator.insert_html(:top, 'element', '<p>This is a test</p>')
    @generator.insert_html(:bottom, 'element', '<p>This is a test</p>')
    @generator.remove('foo', 'bar')
    @generator.replace_html('baz', '<p>This is a test</p>')
    
    assert_equal <<-EOS.chomp, @generator.to_s
new Insertion.Top("element", "<p>This is a test</p>");
new Insertion.Bottom("element", "<p>This is a test</p>");
["foo", "bar"].each(Element.remove);
Element.update("baz", "<p>This is a test</p>");
    EOS
  end
end
